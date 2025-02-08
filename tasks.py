from celery import Celery
import subprocess
import os
from datetime import datetime
import re

app = Celery('chipyard', broker='redis://redis:6379/0', backend='redis://redis:6379/0')
app.conf.task_default_queue = 'chipyard'

def clean_json_string(s):
    s = re.sub(r',(\s*[\]}])', r'\1', s)
    s = re.sub(r'(\s*?{\s*?|\s*?,\s*?)([a-zA-Z_][a-zA-Z0-9_]*)(\s*?:)', r'\1"\2"\3', s)
    return s

def process_log_file(input_filename):
    base_path = os.path.splitext(input_filename)[0]
    
    with open(input_filename, 'r') as f:
        content = f.read()
    
    json_pattern = r'\{[\s\S]*?title:\s*"([^"]+)"[\s\S]*?\}'
    matches = re.finditer(json_pattern, content)
    
    for match in matches:
        json_str = match.group(0)
        title = match.group(1)
        
        title_cleaned = re.sub(r'[^a-zA-Z0-9]+', '-', title)
        output_filename = f"{title_cleaned}_{base_path.split('_', 1)[1]}.json"
        
        cleaned_json = clean_json_string(json_str)
        
        output_dir = os.path.dirname(input_filename)
        output_path = os.path.join(output_dir, output_filename)
        
        with open(output_path, 'w') as f:
            f.write(cleaned_json)

@app.task
def run_benchmark_task(binary_path, benchmark_name, config):
    command_str = (
        f"source /chipyard/env.sh && "  
        f"make -C /chipyard/sims/verilator run-binary "
        f"CONFIG={config} LOADMEM=1 EXTRA_SIM_FLAGS=+cospike-printf=0 "
        f"TIMEOUT_CYCLES=999999999999999999 BINARY={binary_path}"
    )

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    results_dir = os.path.join(os.environ['RESULTS_DIR'], config)
    os.makedirs(results_dir, exist_ok=True)
    output_file = os.path.join(results_dir, f"{benchmark_name}_{config}_{timestamp}.log")

    with open(output_file, "w") as outfile:
        process = subprocess.Popen(['bash', '-c', command_str], stdout=outfile, stderr=subprocess.STDOUT)
        process.wait()

    if process.returncode == 0:
        process_log_file(output_file)

    return process.returncode
