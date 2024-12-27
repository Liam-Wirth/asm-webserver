import asyncio
import aiohttp
import time
import statistics
import argparse
import random
from collections import defaultdict
from rich.console import Console
from rich.table import Table
from rich.progress import Progress
from typing import List, Dict

console = Console()

class ServerStressTest:
    def __init__(self, base_url: str, pages: List[str], num_requests: int, concurrency: int):
        self.base_url = base_url.rstrip('/')
        self.pages = pages
        self.num_requests = num_requests
        self.concurrency = concurrency
        self.results: Dict[str, List[float]] = defaultdict(list)
        self.status_counts: Dict[str, Dict[int, int]] = defaultdict(lambda: defaultdict(int))
        self.errors: Dict[str, List[str]] = defaultdict(list)
        self.connection_semaphore = asyncio.Semaphore(concurrency)

    async def make_request(self, session: aiohttp.ClientSession, page: str, request_id: int):
        url = f"{self.base_url}/{page}"
        async with self.connection_semaphore:  # Limit concurrent connections
            start_time = time.time()
            try:
                async with session.get(url) as response:
                    end_time = time.time()
                    latency = (end_time - start_time) * 1000  # Convert to milliseconds
                    self.results[page].append(latency)
                    self.status_counts[page][response.status] += 1
                    # Read response body to ensure complete transaction
                    await response.read()
                    return latency, response.status, page
            except Exception as e:
                self.errors[page].append(f"{str(e)} (URL: {url})")
                return None, 'error', page

    async def run_test(self):
        # Configure client session with connection pooling
        connector = aiohttp.TCPConnector(limit=self.concurrency)
        timeout = aiohttp.ClientTimeout(total=10)  # 10 seconds timeout
        
        async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
            with Progress() as progress:
                task = progress.add_task("[cyan]Running stress test...", total=self.num_requests)
                
                tasks = []
                for i in range(self.num_requests):
                    # Randomly select a page to test
                    page = random.choice(self.pages)
                    tasks.append(self.make_request(session, page, i))
                    
                    # Process in smaller batches to avoid memory issues
                    if len(tasks) >= self.concurrency * 2:
                        await asyncio.gather(*tasks)
                        progress.update(task, advance=len(tasks))
                        tasks = []
                
                # Process remaining tasks
                if tasks:
                    await asyncio.gather(*tasks)
                    progress.update(task, advance=len(tasks))

    def calculate_page_stats(self, page: str):
        results = self.results[page]
        if not results:
            return None
        
        return {
            'count': len(results),
            'avg': statistics.mean(results),
            'median': statistics.median(results),
            'p95': statistics.quantiles(results, n=20)[18] if len(results) >= 20 else None,
            'p99': statistics.quantiles(results, n=100)[98] if len(results) >= 100 else None,
            'min': min(results),
            'max': max(results),
            'throughput': len(results) / (max(results) / 1000)
        }

    def print_results(self):
        console.print("\n[bold cyan]Overall Test Results[/bold cyan]")
        
        # Print results for each page
        for page in self.pages:
            console.print(f"\n[bold green]Results for /{page}[/bold green]")
            
            stats = self.calculate_page_stats(page)
            if not stats:
                console.print("[red]No successful requests to analyze!")
                continue

            # Create results table
            table = Table()
            table.add_column("Metric", style="cyan")
            table.add_column("Value", style="green")
            
            table.add_row("Total Requests", str(stats['count']))
            table.add_row("Failed Requests", str(len(self.errors[page])))
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

            # Print status code distribution
            status_table = Table(title="Status Code Distribution")
            status_table.add_column("Status Code", style="cyan")
            status_table.add_column("Count", style="green")
            
            for status, count in self.status_counts[page].items():
                status_table.add_row(str(status), str(count))
                
            console.print(status_table)

            # Print errors if any
            if self.errors[page]:
                console.print("\n[red]Errors encountered:")
                for error in self.errors[page][:10]:  # Show first 10 errors
                    console.print(f"- {error}")
                if len(self.errors[page]) > 10:
                    console.print(f"... and {len(self.errors[page]) - 10} more errors")

def main():
    parser = argparse.ArgumentParser(description='Web Server Stress Test')
    parser.add_argument('--url', default='http://localhost:8270', help='Server base URL')
    parser.add_argument('--pages', nargs='+', default=['', 'index.html', '404.html', 'nope.html'], 
                        help='Pages to test (relative paths)')
    parser.add_argument('--requests', type=int, default=1000, help='Number of requests')
    parser.add_argument('--concurrency', type=int, default=10, help='Concurrent connections')
    args = parser.parse_args()

    stress_test = ServerStressTest(args.url, args.pages, args.requests, args.concurrency)
    
    console.print(f"[cyan]Starting stress test against {args.url}")
    console.print(f"[cyan]Testing pages: {', '.join(args.pages)}")
    console.print(f"[cyan]Total requests: {args.requests}")
    console.print(f"[cyan]Concurrent connections: {args.concurrency}\n")

    asyncio.run(stress_test.run_test())
    stress_test.print_results()

if __name__ == "__main__":
    main()

