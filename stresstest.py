import asyncio
import aiohttp
import time
import statistics
import argparse
import random
import string
from collections import defaultdict
from rich.console import Console
from rich.table import Table
from rich.progress import Progress
from typing import List, Dict
from testcats import *

console = Console()

class ServerStressTest:
    def __init__(self, base_url: str, num_requests: int, concurrency: int, 
                 include_security_tests: bool = False):
        self.base_url = base_url.rstrip('/')
        self.num_requests = num_requests
        self.concurrency = concurrency
        self.include_security_tests = include_security_tests
        self.results: Dict[str, List[float]] = defaultdict(list)
        self.status_counts: Dict[str, Dict[int, int]] = defaultdict(lambda: defaultdict(int))
        self.errors: Dict[str, List[str]] = defaultdict(list)
        self.connection_semaphore = asyncio.Semaphore(concurrency)
        
        # Generate random paths for testing
        self.generate_random_paths()
        
        # Generate test URLs
        self.test_urls = self.generate_test_urls()

    def generate_random_paths(self, num_paths=5, min_length=100, max_length=500):
        """Generate random paths for testing"""
        for _ in range(num_paths):
            length = random.randint(min_length, max_length)
            random_path = ''.join(random.choices(string.ascii_lowercase + string.digits, k=length))
            RESULT_GROUPS['Random Paths'].append(random_path)

    def generate_test_urls(self) -> List[str]:
        """Generate all test URLs based on configuration"""
        urls = []
        if self.include_security_tests:
            for group in RESULT_GROUPS.values():
                urls.extend(group)
        else:
            urls.extend(RESULT_GROUPS['Valid Pages'])
        return urls

    async def make_request(self, session: aiohttp.ClientSession, page: str, request_id: int):
        url = f"{self.base_url}/{page}"
        async with self.connection_semaphore:
            start_time = time.time()
            try:
                async with session.get(url) as response:
                    end_time = time.time()
                    latency = (end_time - start_time) * 1000
                    self.results[page].append(latency)
                    self.status_counts[page][response.status] += 1
                    await response.read()
                    return latency, response.status, page
            except Exception as e:
                self.errors[page].append(f"{str(e)} (URL: {url})")
                return None, 'error', page

    async def run_test(self):
        connector = aiohttp.TCPConnector(limit=self.concurrency)
        timeout = aiohttp.ClientTimeout(total=10)
        
        async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
            with Progress() as progress:
                task = progress.add_task("[cyan]Running stress test...", total=self.num_requests)
                
                tasks = []
                for i in range(self.num_requests):
                    page = random.choice(self.test_urls)
                    tasks.append(self.make_request(session, page, i))
                    
                    if len(tasks) >= self.concurrency * 2:
                        await asyncio.gather(*tasks)
                        progress.update(task, advance=len(tasks))
                        tasks = []
                
                if tasks:
                    await asyncio.gather(*tasks)
                    progress.update(task, advance=len(tasks))

    def calculate_aggregate_stats(self, latencies: List[float]):
        if not latencies:
            return None
        
        return {
            'count': len(latencies),
            'avg': statistics.mean(latencies),
            'median': statistics.median(latencies),
            'p95': statistics.quantiles(latencies, n=20)[18] if len(latencies) >= 20 else None,
            'p99': statistics.quantiles(latencies, n=100)[98] if len(latencies) >= 100 else None,
            'min': min(latencies),
            'max': max(latencies),
            'throughput': len(latencies) / (max(latencies) / 1000)
        }

    def print_group_results(self, group_name: str, paths: List[str]):
        console.print(f"\n[bold yellow]{group_name}[/bold yellow]")
        
        # Aggregate metrics
        all_latencies = []
        status_counts = defaultdict(int)
        total_errors = 0
        
        for path in paths:
            if path in self.results:
                all_latencies.extend(self.results[path])
                for status, count in self.status_counts[path].items():
                    status_counts[status] += count
                total_errors += len(self.errors[path])
        
        if not all_latencies:
            console.print("[red]No requests in this group[/red]")
            return
            
        stats = self.calculate_aggregate_stats(all_latencies)
        
        # Print results table
        table = Table()
        table.add_column("Metric", style="cyan")
        table.add_column("Value", style="green")
        
        table.add_row("Total Requests", str(stats['count']))
        table.add_row("Failed Requests", str(total_errors))
        table.add_row("Average Latency", f"{stats['avg']:.2f}ms")
        table.add_row("Median Latency", f"{stats['median']:.2f}ms")
        if stats['p95']:
            table.add_row("95th Percentile", f"{stats['p95']:.2f}ms")
        if stats['p99']:
            table.add_row("99th Percentile", f"{stats['p99']:.2f}ms")
        table.add_row("Min Latency", f"{stats['min']:.2f}ms")
        table.add_row("Max Latency", f"{stats['max']:.2f}ms")
        table.add_row("Requests/Second", f"{stats['throughput']:.2f}")
        
        console.print(table)

        # Print status distribution
        status_table = Table(title="Status Code Distribution")
        status_table.add_column("Status Code", style="cyan")
        status_table.add_column("Count", style="green")
        
        for status, count in sorted(status_counts.items()):
            status_table.add_row(str(status), str(count))
            
        console.print(status_table)

    def print_security_summary(self):
        console.print("\n[bold red]Security Test Summary[/bold red]")
        
        security_table = Table()
        security_table.add_column("Test Type", style="cyan")
        security_table.add_column("Total Requests", style="yellow")
        security_table.add_column("Blocked (4xx)", style="green")
        security_table.add_column("Allowed (2xx/3xx)", style="red")
        security_table.add_column("Errors", style="red")

        for group_name in ['Path Traversal', 'Malicious Paths', 'Special Characters']:
            paths = RESULT_GROUPS[group_name]
            total = sum(len(self.results[p]) for p in paths)
            blocked = sum(sum(count for status, count in self.status_counts[p].items() 
                            if 400 <= status < 500)
                         for p in paths)
            allowed = sum(sum(count for status, count in self.status_counts[p].items() 
                            if status < 400)
                         for p in paths)
            errors = sum(len(self.errors[p]) for p in paths)

            security_table.add_row(
                group_name,
                str(total),
                str(blocked),
                str(allowed),
                str(errors)
            )

        console.print(security_table)

    def print_results(self):
        console.print("\n[bold cyan]Test Results Summary[/bold cyan]")
        
        # Print results for each group
        for group_name, paths in RESULT_GROUPS.items():
            if paths:  # Only print groups that have paths
                self.print_group_results(group_name, paths)
        
        if self.include_security_tests:
            self.print_security_summary()

def main():
    parser = argparse.ArgumentParser(description='Web Server Stress Test')
    parser.add_argument('--url', default='http://localhost:8270', help='Server base URL')
    parser.add_argument('--requests', type=int, default=1000, help='Number of requests')
    parser.add_argument('--concurrency', type=int, default=10, help='Concurrent connections')
    parser.add_argument('--security', action='store_true', help='Include security tests')
    args = parser.parse_args()

    stress_test = ServerStressTest(args.url, args.requests, args.concurrency, args.security)
    
    console.print(f"[cyan]Starting stress test against {args.url}")
    console.print(f"[cyan]Total requests: {args.requests}")
    console.print(f"[cyan]Concurrent connections: {args.concurrency}")
    if args.security:
        console.print("[red]Including security tests!")

    asyncio.run(stress_test.run_test())
    stress_test.print_results()

if __name__ == "__main__":
    main()

