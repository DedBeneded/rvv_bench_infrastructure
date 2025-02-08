import json
import glob
import nbformat as nbf
from pathlib import Path
import yaml
import os
import re


def get_config_name(json_filename):
    parts = json_filename.split('_')
    for part in parts:
        if part.endswith('Config'):
            return part
    return None


def extract_benchmark_name(filename):
    match = re.match(r'([a-zA-Z0-9-]+(?:[_-][a-zA-Z0-9-]+)*?)_', filename)
    if match:
        return match.group(1)
    return filename


def extract_date(filename):
    match = re.search(r'(\d{8})_\d{6}', filename)
    if match:
        return match.group(1)
    return "Unknown Date"


def create_notebook_from_jsons(json_dir="/results", output_file="/workspace/analysis.ipynb"):
    nb = nbf.v4.new_notebook()

    imports_cell = nbf.v4.new_code_cell('''
import json
import matplotlib.pyplot as plt
''')
    nb.cells.append(imports_cell)

    plot_function_cell = nbf.v4.new_code_cell('''
def plot_from_json(json_file):
    try:
        with open(json_file, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Ошибка: Файл {json_file} не найден.")
        return
    except json.JSONDecodeError:
        print(f"Ошибка: Некорректный формат JSON в файле {json_file}.")
        return

    title = data.get("title", "График")
    labels = data.get("labels", [])
    data_points = data.get("data", [])

    if not data_points:
        print("Ошибка: Отсутствуют данные для построения графика.")
        return

    if len(data_points) == 0:
        print("Ошибка: Отсутствуют данные для построения графика (data пуст).")
        return

    x_values = data_points[0]

    if len(labels) != len(data_points):
        print("Ошибка: Количество меток не соответствует количеству строк данных.")
        return

    if any(len(row) != len(x_values) for row in data_points):
        print("Ошибка: Не все строки данных имеют одинаковую длину.")
        return

    plt.figure(figsize=(12, 6)) 
    plt.title(title)
    xticks = list(range(len(x_values)))
    plt.xticks(xticks, x_values)

    for i, y_values in enumerate(data_points[1:]):
        plt.plot(xticks, y_values, label=data['labels'][i + 1])

    plt.yscale('log')
    plt.xlabel(labels[0])
    plt.ylabel("Byte/Cycle")
    plt.legend(loc='center left', bbox_to_anchor=(1, 0.5))
    plt.grid(True, which="both", ls="--", alpha=0.7)
    plt.tight_layout(rect=[0, 0, 0.85, 1])
    plt.show()
''')
    nb.cells.append(plot_function_cell)

    config_groups = {}

    for root, dirs, files in os.walk(json_dir):
        if root == json_dir or root.count(os.sep) == json_dir.count(os.sep) + 1:
            for file in files:
                if file.endswith(".json"):
                    json_file = os.path.join(root, file)
                    config_name = get_config_name(file)
                    if config_name:
                        if config_name not in config_groups:
                            config_groups[config_name] = []
                        config_groups[config_name].append(json_file)

    sorted_configs = sorted(config_groups.keys())

    for config_name in sorted_configs:
        header1_cell = nbf.v4.new_markdown_cell(f"# {config_name}")
        nb.cells.append(header1_cell)

        json_files = sorted(config_groups[config_name])

        for json_file in json_files:
            filename = Path(json_file).stem
            benchmark_name = extract_benchmark_name(filename)
            benchmark_date = extract_date(filename)

            header2_cell = nbf.v4.new_markdown_cell(f"## {benchmark_name}")
            nb.cells.append(header2_cell)

            try:
                with open('./configs.yaml', 'r') as yaml_file:
                    yaml_data = yaml.safe_load(yaml_file)['configs']

                if config_name in yaml_data and "description" in yaml_data[config_name]:
                    desc_cell = nbf.v4.new_markdown_cell(
                        f"**Configuration:** {yaml_data[config_name]['description']}<br>"
                        f"**Benchmark:** {benchmark_name}<br>"
                        f"**Date:** {benchmark_date}"
                    )
                    nb.cells.append(desc_cell)
                else:
                    desc_cell = nbf.v4.new_markdown_cell(
                        f"**Configuration:** {config_name} (No description available)<br>"
                        f"**Benchmark:** {benchmark_name}<br>"
                        f"**Date:** {benchmark_date}"
                    )
                    nb.cells.append(desc_cell)


            except Exception as e:
                print(f"Error loading description: {e}")
                desc_cell = nbf.v4.new_markdown_cell(
                    f"**Configuration:** {config_name} (Error loading description)<br>"
                    f"**Benchmark:** {benchmark_name}<br>"
                    f"**Date:** {benchmark_date}"
                )
                nb.cells.append(desc_cell)

            plot_cell = nbf.v4.new_code_cell(f'plot_from_json("{json_file}")')
            nb.cells.append(plot_cell)

    with open(output_file, 'w') as f:
        nbf.write(nb, f)


if __name__ == "__main__":
    create_notebook_from_jsons()
