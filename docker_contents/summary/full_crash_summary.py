#!/bin/python3

import sys
import os
import shutil

def main():
    if len(sys.argv) != 3:
        print("Incorrect arg count.")
        print("Usage: ./exe <report_dir> <output_dir>")
        return

    report_dir = sys.argv[1]
    output_dir = sys.argv[2]

    if not os.path.isdir(report_dir):
        print(f'Directory "{report_dir}" does not exist')
        return

    os.makedirs(output_dir, exist_ok=True)
    full_output_dir = os.path.join(output_dir, 'full')
    os.makedirs(full_output_dir, exist_ok=True)
    reverse_output_dir = os.path.join(output_dir, 'reverse')
    os.makedirs(reverse_output_dir, exist_ok=True)
    reverse_read_out_dir = os.path.join(reverse_output_dir, 'read')
    os.makedirs(reverse_read_out_dir, exist_ok=True)
    reverse_write_out_dir = os.path.join(reverse_output_dir, 'write')
    os.makedirs(reverse_write_out_dir, exist_ok=True)

    outputs = {}

    for entry in os.scandir(report_dir):
        if not entry.is_file():
            continue
        
        source_file, mode, executable = entry.name.split('.')
        with open(entry.path, 'r') as crash_report:
            contents = crash_report.read().strip()
            if contents == "":
                continue
            
            if not source_file in outputs:
                outputs[source_file] = []

            content_desc = (mode, executable, contents)
            
            outputs[source_file] += [content_desc]
            
    for file_name, content_list in outputs.items():
        out_file_name = os.path.join(full_output_dir, f'{file_name}.summary')
        with open(out_file_name, 'w') as output_file:
            for content_desc in content_list:
                mode, executable, contents = content_desc[:]
                output_file.write(f'==========> {mode}.{executable}: {contents}\n')

    # associate error message with source input file
    reverse_outputs = {}
    for file_name, content_list in outputs.items():
        for content_desc in content_list:
            mode, executable, contents = content_desc[:]
            content_lines = contents.splitlines()
            summary_line = next((line for line in content_lines if "READ of" in line or "WRITE of" in line), None)
            if summary_line:
                contents = summary_line

            if not contents in reverse_outputs:
                reverse_outputs[contents] = []
            
            file_desc = (file_name, mode, executable)
            reverse_outputs[contents] += [file_desc]
    
    print(f'Counted {len(reverse_outputs)} unique error messages...')
    print('Only storing errors containing "READ of" or "WRITE of" in reverse directory...')

    # if this needs to be faster, merge the below two loops

    reverse_read_summary_fname = os.path.join(reverse_read_out_dir, 'list.txt')
    reverse_write_summary_fname = os.path.join(reverse_write_out_dir, 'list.txt')
    reverse_read_file = open(reverse_read_summary_fname, 'w')
    reverse_write_file = open(reverse_write_summary_fname, 'w')
    for error, file_list in reverse_outputs.items():
        target_file = None
        if "READ of" in error:
            target_file = reverse_read_file
        elif "WRITE of" in error:
            target_file = reverse_write_file
        else:
            continue;
        file_name, mode, executable = file_list[0]
        target_file.write(f'{file_name} {mode} {executable}\n')
    reverse_read_file.close()
    reverse_write_file.close()


    index = 1
    for error, file_list in reverse_outputs.items():
        sub_folder = None
        if "READ of" in error:
            sub_folder = reverse_read_out_dir
        elif "WRITE of" in error:
            sub_folder = reverse_write_out_dir
        else:
            continue;
        index_str = str(index).zfill(3)
        out_file_name = os.path.join(sub_folder, f'{index_str}.summary')
        with open(out_file_name, 'w') as output_file:
            output_file.write(f'{error}\n\n')
            for file_desc in file_list:
                file_name, mode, executable = file_desc[:]
                output_file.write(f'{file_name}, {mode}, {executable}\n')

        index += 1


if __name__ == "__main__":
    main()
