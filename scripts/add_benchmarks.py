import argparse
import subprocess
import os
import yaml
import json

def get_benchmarks():
    with open("/chipyard/benchmarks.list", "r") as f:
        return [line.strip() for line in f]

def queue_benchmark(binary_path, config):
    benchmark_name = os.path.basename(binary_path)
    args_list = [binary_path, benchmark_name, config]
    args_json = json.dumps(args_list)
    subprocess.run([
        "celery", "-A", "tasks", "call", "tasks.run_benchmark_task",
        "--args", args_json
    ], check=True)

def main():
    parser = argparse.ArgumentParser(description="Add benchmarks to Celery queue.")
    parser.add_argument("--bench", type=str, default="all",
                        help="Comma-separated list of benchmarks (or 'all').  e.g., 'memset,memcpy' or 'all'")
    parser.add_argument("--config", type=str, default="",
                        help="Comma-separated list of configs (or leave empty for default). e.g., 'Config1,Config2'")
    parser.add_argument("--list-bench", action="store_true",
                        help="List available benchmarks")
    parser.add_argument("--list-config", action="store_true",
                        help="List available configurations")
    args = parser.parse_args()

    configs_file = "/chipyard/build_configs/configs.yaml"
    with open(configs_file, 'r') as f:
        configs_data = yaml.safe_load(f)
        available_configs = list(configs_data['configs'].keys())

    if args.list_bench:
        print("Available benchmarks:")
        for bench in get_benchmarks():
            print(f"  - {os.path.basename(bench)}")
        return

    if args.list_config:
        print("Available configurations:")
        for config in available_configs:
            print(f"  - {config}")
        return

    if args.bench == "all":
        benchmarks = get_benchmarks()
    else:
        benchmarks_to_find = args.bench.split(',')
        all_benchmarks = get_benchmarks()
        benchmarks = []
        for requested_bench in benchmarks_to_find:
            found = False
            for actual_bench in all_benchmarks:
                if os.path.basename(actual_bench) == requested_bench:
                    benchmarks.append(actual_bench)
                    found = True
                    break
            if not found:
                print(f"Warning: Benchmark '{requested_bench}' not found.")


    if not args.config:
        configs = [os.environ.get('CONFIG', available_configs[0])]
    else:
        configs = args.config.split(',')
        for config in configs:
            if config not in available_configs:
                print(f"Error: Config '{config}' is not valid.")
                exit(1)

    for config in configs:
        for benchmark in benchmarks:
            queue_benchmark(benchmark, config)
    print(f"Added {len(benchmarks) * len(configs)} tasks to the queue.")

if __name__ == "__main__":
    main()
