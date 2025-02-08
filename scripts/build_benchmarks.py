#!/usr/bin/env python3

import yaml
import subprocess
import os
import shutil
from pathlib import Path

def build_benchmark(bench_name, bench_config, benchmarks_dir):
    """Собирает один бенчмарк."""
    print(f"Building benchmark: {bench_name}")

    if 'repo' in bench_config:
        repo_url = bench_config['repo']
        branch = bench_config.get('branch', 'master')
        target_dir = os.path.join(benchmarks_dir, bench_name)

        if os.path.exists(target_dir):
            print(f"  Benchmark directory {target_dir} already exists.")
            if os.path.exists(os.path.join(target_dir, ".git")):
                print(f"  Updating Git repository...")
                subprocess.run(["git", "pull"], cwd=target_dir, check=True)
                subprocess.run(["git", "checkout", branch], cwd=target_dir, check=True)
            else:
                print(f"  {target_dir} is not a Git repository. Cloning and preserving existing files...")
                temp_dir = target_dir + "_temp"
                try:
                    shutil.copytree(target_dir, temp_dir)
                    shutil.rmtree(target_dir)
                    subprocess.run(["git", "clone", "--recursive", repo_url, target_dir], check=True)
                    subprocess.run(["git", "checkout", branch], cwd=target_dir, check=True)
                    for item in os.listdir(temp_dir):
                        s = os.path.join(temp_dir, item)
                        d = os.path.join(target_dir, item)
                        if os.path.isdir(s):
                            shutil.copytree(s, d, dirs_exist_ok=True)
                        else:
                            shutil.copy2(s, d)
                finally:
                    if os.path.exists(temp_dir):
                        shutil.rmtree(temp_dir)
        else:
            print(f"  Cloning repository...")
            subprocess.run(["git", "clone", "--recursive", repo_url, target_dir], check=True)
            subprocess.run(["git", "checkout", branch], cwd=target_dir, check=True)

        src_dir = bench_config.get('src_dir', '.')
        bench_dir = os.path.join(target_dir, src_dir)

    elif 'path' in bench_config:
        bench_dir = os.path.join(benchmarks_dir, bench_config['path'])
    else:
        raise ValueError(f"Invalid benchmark configuration: {bench_name}")

    if 'patches' in bench_config:
        for patch_file in bench_config['patches']:
            patch_path = os.path.join(bench_dir, patch_file)
            print(f"  Applying patch: {patch_path}")
            subprocess.run(["patch", "-p1", "-i", patch_path], cwd=bench_dir, check=True)

    if 'config' in bench_config:
        if bench_name == 'rvv_bench': 
            config_mk_path = os.path.join(bench_dir, "config.mk")
            print(f"  Creating config.mk: {config_mk_path}")
            with open(config_mk_path, "w") as f:
                f.write(f"CC=riscv64-unknown-elf-gcc\n")
                for key, value in bench_config['compiler_flags'].items():
                    f.write(f"{key}={value}\n")

            config_h_path = os.path.join(bench_dir, "bench", "config.h")
            print(f"  Creating config.h: {config_h_path}")
            with open(config_h_path, "w") as f:
                for key, config in bench_config['config'].items():
                    if 'params' in config:
                        params = '(' + ','.join(config['params']) + ')'
                        f.write(f"#define {key}{params} {config['value']}\n")
                    else:
                        f.write(f"#define {key} {config['value']}\n")

    build_script = bench_config['build_script']
    build_script_path = os.path.join(bench_dir, build_script)
    print(f"  Running build script: {build_script_path}")
    subprocess.run([build_script_path], cwd=bench_dir, check=True, env={**os.environ, **bench_config.get('compiler_flags', {})})


def main():
    """Основная функция."""
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    benchmarks_dir = "/chipyard/tests"
    build_config_path = project_root / "build_configs" / "build_config.yaml"
    benchmarks_file = project_root / "benchmarks.list"

    with open(build_config_path, "r") as f:
        build_config = yaml.safe_load(f)

    all_benchmarks = []
    for bench_name, bench_config in build_config['benchmarks'].items():
        build_benchmark(bench_name, bench_config, benchmarks_dir)

        if 'repo' in bench_config:
            src_dir = bench_config.get('src_dir', '.')
            bench_dir = os.path.join(benchmarks_dir, bench_name, src_dir)
        elif 'path' in bench_config:
            bench_dir = os.path.join(benchmarks_dir, bench_config['path'])

        for root, _, files in os.walk(bench_dir):
            for file in files:
                file_path = os.path.join(root, file)
                if os.access(file_path, os.X_OK) and '.' not in file:
                    all_benchmarks.append(file_path)

    with open(benchmarks_file, "w") as f:
        for bench_path in all_benchmarks:
            f.write(f"{bench_path}\n")

    print("Benchmark build complete.")

if __name__ == "__main__":
    main()
