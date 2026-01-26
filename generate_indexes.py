#!/usr/bin/env python3
"""
Generate index.html files for all directories containing .html files
or subdirectories with .html files.
"""

import os
from pathlib import Path
from collections import defaultdict
import html

def has_html_files(directory):
    """Check if directory contains any .html files (not counting index.html)"""
    try:
        for entry in os.listdir(directory):
            if entry.endswith('.html') and entry != 'index.html':
                return True
    except (OSError, PermissionError):
        pass
    return False

def has_html_subdirs(directory):
    """Check if directory has subdirectories containing .html files"""
    try:
        for entry in os.listdir(directory):
            full_path = os.path.join(directory, entry)
            if os.path.isdir(full_path):
                if has_html_files_recursive(full_path):
                    return True
    except (OSError, PermissionError):
        pass
    return False

def has_html_files_recursive(directory):
    """Recursively check if directory or its subdirectories have .html files"""
    try:
        for entry in os.listdir(directory):
            full_path = os.path.join(directory, entry)
            if entry.endswith('.html'):
                return True
            if os.path.isdir(full_path):
                if has_html_files_recursive(full_path):
                    return True
    except (OSError, PermissionError):
        pass
    return False

def generate_index_html(directory):
    """Generate an index.html file for the given directory"""
    
    # Get list of .html files (excluding index.html)
    html_files = []
    subdirs_with_html = []
    
    try:
        entries = sorted(os.listdir(directory))
        
        for entry in entries:
            full_path = os.path.join(directory, entry)
            
            if os.path.isfile(full_path) and entry.endswith('.html') and entry != 'index.html':
                html_files.append(entry)
            elif os.path.isdir(full_path) and has_html_files_recursive(full_path):
                subdirs_with_html.append(entry)
    except (OSError, PermissionError) as e:
        print(f"Error reading directory {directory}: {e}")
        return False
    
    # Only generate if there are files or subdirs to list
    if not html_files and not subdirs_with_html:
        return False
    
    # Get relative path from root for title
    rel_path = os.path.relpath(directory, '/workspaces/acl2/docs')
    if rel_path == '.':
        title = "ACL2 Documentation Index"
    else:
        title = f"Index of {rel_path}"
    
    # Generate HTML content
    html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{html.escape(title)}</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }}
        h1 {{
            color: #333;
            border-bottom: 2px solid #0066cc;
            padding-bottom: 10px;
        }}
        h2 {{
            color: #555;
            margin-top: 30px;
        }}
        .file-list, .dir-list {{
            list-style: none;
            padding: 0;
        }}
        .file-list li, .dir-list li {{
            background: white;
            margin: 5px 0;
            padding: 10px;
            border-radius: 4px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }}
        .file-list a, .dir-list a {{
            color: #000;
            text-decoration: none;
            font-family: 'Courier New', Courier, monospace;
            font-weight: bold;
        }}
        .file-list a:hover, .dir-list a:hover {{
            text-decoration: underline;
            color: #0066cc;
        }}
        .dir-list a::before {{
            content: "📁 ";
        }}
        .file-list a::before {{
            content: "📄 ";
        }}
    </style>
</head>
<body>
    <h1>{html.escape(title)}</h1>
"""
    
    # Add subdirectories section if any
    if subdirs_with_html:
        html_content += "    <h2>Directories</h2>\n"
        html_content += '    <ul class="dir-list">\n'
        for subdir in subdirs_with_html:
            html_content += f'        <li><a href="{html.escape(subdir)}/index.html">{html.escape(subdir)}</a></li>\n'
        html_content += "    </ul>\n"
    
    # Add files section if any
    if html_files:
        html_content += "    <h2>Files</h2>\n"
        html_content += '    <ul class="file-list">\n'
        for file in html_files:
            # Use the unmodified filename (without .html extension)
            display_name = file[:-5]
            html_content += f'        <li><a href="{html.escape(file)}">{html.escape(display_name)}</a></li>\n'
        html_content += "    </ul>\n"
    
    html_content += """</body>
</html>
"""
    
    # Write the index.html file
    index_path = os.path.join(directory, 'index.html')
    try:
        with open(index_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
        print(f"Generated: {index_path}")
        return True
    except (OSError, PermissionError) as e:
        print(f"Error writing {index_path}: {e}")
        return False

def find_and_generate_indexes(root_dir):
    """Walk through directory tree and generate indexes where needed"""
    generated_count = 0
    
    for dirpath, dirnames, filenames in os.walk(root_dir):
        # Skip hidden directories and common ignore patterns
        dirnames[:] = [d for d in dirnames if not d.startswith('.') and d not in ['__pycache__', 'node_modules']]
        
        # Check if this directory needs an index
        needs_index = False
        
        # Check if there are .html files (other than index.html)
        has_html = any(f.endswith('.html') and f != 'index.html' for f in filenames)
        
        # Check if there are subdirs with .html files
        has_subdir_html = False
        for dirname in dirnames:
            subdir_path = os.path.join(dirpath, dirname)
            if has_html_files_recursive(subdir_path):
                has_subdir_html = True
                break
        
        if has_html or has_subdir_html:
            if generate_index_html(dirpath):
                generated_count += 1
    
    return generated_count

if __name__ == '__main__':
    root_directory = '/workspaces/acl2/docs'
    print(f"Scanning {root_directory} for directories needing index.html files...")
    count = find_and_generate_indexes(root_directory)
    print(f"\nComplete! Generated {count} index.html files.")
