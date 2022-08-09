#!/usr/bin/env python3

# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

import argparse
import pathlib
import re
import csv
import operator

from pytablewriter import MarkdownTableWriter
from pytablewriter.style import Style
from mako.template import Template


# Compile a regex to trim trailing whitespaces on lines.
re_trailws = re.compile(r'[ \t\r]+$', re.MULTILINE)


def write_template(tpl_path: str, outdir: pathlib.Path, **kwargs):
    if tpl_path:
        tpl_path = pathlib.Path(tpl_path).absolute()
        print(tpl_path)
        if tpl_path.exists():
            tpl = Template(filename=str(tpl_path))
            with open(outdir / tpl_path.with_suffix("").name, "w") as file:
                code = tpl.render_unicode(**kwargs)
                code = re_trailws.sub("", code)
                file.write(code)
        else:
            # print(outdir, tpl_path)
            raise FileNotFoundError


def get_size_string(size: int):
    size_str = ""
    if size >= 1024*1024*1024*1024:
        scaled_size = size/(1024*1024*1024*1024)
        size_str = "{:.1f} TB".format(scaled_size)
    elif size >= 1024*1024*1024:
        scaled_size = size/(1024*1024*1024)
        size_str = "{:.1f} GB".format(scaled_size)
    elif size >= 1024*1024:
        scaled_size = size/(1024*1024)
        size_str = "{:.1f} MB".format(scaled_size)
    elif size >= 1024:
        scaled_size = size/(1024)
        size_str = "{:.1f} KB".format(scaled_size)
    else:
        scaled_size = size
        size_str = "{:.1f} B".format(scaled_size)
    return size_str


def get_label_pos(max_nr_merged_entries: int):
    half = max_nr_merged_entries / 2
    (idx0, idx1) = (0, 0)
    if (max_nr_merged_entries % 2) == 0:
        idx0 = int(half-1)
        idx1 = int(half)
    else:
        idx0 = int(half)
        idx1 = int(half)+1
    return (idx0, idx1)


def main(file: str, outdir: pathlib.Path, tex_filename: str, md_filename: str):

    # initialize values
    quadrant_range_start = 2**64
    quadrant_range_end = 0
    quadrant_range_size = 0

    max_quadrant_index = 0

    all_entries = []
    all_quadrant_entries = []

    reader = csv.DictReader(file)
    for row in reader:

        # get strings for template
        start_addr = int(row['start_addr'])
        start_addr_str = "0x{:09_x}".format(start_addr)

        end_addr = int(row['end_addr'])
        end_addr_str = "0x{:09_x}".format(end_addr)

        size = int(row['size'])
        size_str = get_size_string(size)

        # collect into dict
        entry = {
            'name': row['name'].upper().replace("_", "\\_"),
            'start_addr_str': start_addr_str.replace("_", "\\_"),
            'start_addr': start_addr,
            'end_addr_str': end_addr_str.replace("_", "\\_"),
            'end_addr': end_addr,
            'size': size_str.replace("_", "\\_")
        }

        # collect all_quadrant_entries seperately for "zoom-in" graphic
        if ("quadrant" in str(row['name'])):
            quadrant_idx = int(re.search(r'\d+', row['name']).group())
            if (quadrant_idx > max_quadrant_index):
                max_quadrant_index = quadrant_idx
            all_quadrant_entries.append(entry)
            if start_addr < quadrant_range_start:
                quadrant_range_start = start_addr
            if end_addr > quadrant_range_end:
                quadrant_range_end = end_addr
            quadrant_range_size += size
        else:
            all_entries.append(entry)

    # sort lists by starting address
    all_entries.sort(key=operator.itemgetter('start_addr'))
    all_quadrant_entries.sort(key=operator.itemgetter('start_addr'))

    # add "empty" filler entries
    old_entry = {}
    quadrant_filler = {}
    all_entries_filled = []
    added_quadrant = 0
    added_quadrant_old = 0
    md_occamy_list = []
    for entry in all_entries:

        filler_entry = None

        # add QUADRANTS block entry at correct position
        if (entry['start_addr'] >= quadrant_range_start) and (added_quadrant == 0):
            filler_entry_start_addr = quadrant_range_start
            filler_entry_start_addr_str = "0x{:09_x}".format(filler_entry_start_addr)

            filler_entry_end_addr = quadrant_range_end
            filler_entry_end_addr_str = "0x{:09_x}".format(filler_entry_end_addr)

            filler_entry_size = quadrant_range_size
            filler_entry_size_str = get_size_string(filler_entry_size)

            filler_entry_name = "QUADRANTS"

            filler_entry = {
                'name': filler_entry_name,
                'start_addr_str': filler_entry_start_addr_str.replace("_", "\\_"),
                'start_addr': filler_entry_start_addr,
                'end_addr_str': filler_entry_end_addr_str.replace("_", "\\_"),
                'end_addr': filler_entry_end_addr,
                'size': filler_entry_size_str.replace("_", "\\_")
            }
            added_quadrant = 1
            all_entries_filled.append(filler_entry)
            md_occamy_list.append([
                filler_entry['name'],
                filler_entry['size'],
                "used",
                filler_entry['start_addr_str'],
                filler_entry['end_addr_str']
            ])

        # add EMTPY block entry at correct position
        if (old_entry != {}):
            filler_entry_end_addr = entry['start_addr']-1
            filler_entry_start_addr = 0
            # consider added quadrant block
            if added_quadrant_old == added_quadrant:
                filler_entry_start_addr = old_entry['end_addr']+1
            else:
                filler_entry_start_addr = quadrant_range_end+1

            if (filler_entry_end_addr-1 > filler_entry_start_addr):

                filler_entry_start_addr_str = "0x{:09_x}".format(filler_entry_start_addr)
                filler_entry_end_addr_str = "0x{:09_x}".format(filler_entry_end_addr)

                filler_entry_size = filler_entry_end_addr - filler_entry_start_addr
                filler_entry_size_str = get_size_string(filler_entry_size)

                filler_entry_name = "EMPTY"

                filler_entry = {
                    'name':           filler_entry_name,
                    'start_addr_str': filler_entry_start_addr_str.replace("_", "\\_"),
                    'start_addr':     filler_entry_start_addr,
                    'end_addr_str':   filler_entry_end_addr_str.replace("_", "\\_"),
                    'end_addr':       filler_entry_end_addr,
                    'size':           filler_entry_size_str.replace("_", "\\_")
                }
                all_entries_filled.append(filler_entry)
                md_occamy_list.append([
                    "-",
                    filler_entry['size'],
                    "free",
                    filler_entry['start_addr_str'],
                    filler_entry['end_addr_str']
                ])
                # store quadrant filler entry
                if not (added_quadrant_old == added_quadrant):
                    quadrant_filler = dict(filler_entry)

        # keep normal entry
        all_entries_filled.append(entry)
        md_occamy_list.append([
            entry['name'],
            entry['size'],
            "used",
            entry['start_addr_str'],
            entry['end_addr_str']
        ])

        # update old_entry to new entry
        old_entry = entry
        added_quadrant_old = added_quadrant

    nr_q_entries = len(all_quadrant_entries)

    # Quadrant latex
    NR_QUADRANTS = max_quadrant_index + 1
    NR_CLUSTER_ADDR_RANGES = 3  # tcdm and periphs
    NR_CLUSTERS_PER_QUADRANT = int(nr_q_entries / NR_CLUSTER_ADDR_RANGES / NR_QUADRANTS)

    QUADRANT_SIZE = int(quadrant_range_size / NR_QUADRANTS)
    quadrant_size_str = get_size_string(QUADRANT_SIZE)

    CLUSTER_SIZE = QUADRANT_SIZE / NR_CLUSTERS_PER_QUADRANT
    cluster_size_str = get_size_string(CLUSTER_SIZE)

    # get label positions for quadrant blocks and cluster blocks
    (QIDX0, QIDX1) = get_label_pos(NR_CLUSTERS_PER_QUADRANT)

    all_quadrant_entries_filled = []
    md_quadrants_list = []
    for entry in all_quadrant_entries:
        items = entry['name'].split('\\_')
        qidx = int(items[1])
        cidx = int(items[3])

        tcdm = (items[4] == "TCDM")
        periph = (items[4] == "PERIPH")

        # special layout when only 1 cluster is used
        quadrant_string = ""
        if (NR_CLUSTERS_PER_QUADRANT > 1):
            if cidx == QIDX0 and not tcdm and not periph:
                quadrant_string = quadrant_size_str
            elif cidx == QIDX1 and tcdm:
                quadrant_string = "QUADRANT {}".format(qidx)
        else:
            if cidx == QIDX0 and tcdm:
                quadrant_string = quadrant_size_str
            elif cidx == QIDX0 and periph:
                quadrant_string = "QUADRANT {}".format(qidx)

        quadrant_border = ""
        if (cidx == 0) and tcdm:
            quadrant_border = "lrt"
        elif (cidx == NR_CLUSTERS_PER_QUADRANT-1) and not tcdm and not periph:
            quadrant_border = "lrb"
        else:
            quadrant_border = "lr"

        outer_start_addr = ""
        outer_end_addr = ""
        cluster_string = ""
        cluster_border = ""
        inner_string = ""
        md_string = ""
        if tcdm:
            md_string = "CLUSTER\\_TCDM"
            inner_string = "{} TCDM".format(entry['size'])
            cluster_string = cluster_size_str
            cluster_border = "lrt"
            outer_start_addr = entry['start_addr_str']
        elif periph:
            md_string = "CLUSTER\\_PERIPHERAL"
            inner_string = "{} PERIPHERAL".format(entry['size'])
            cluster_string = "CLUSTER {}".format(cidx)
            cluster_border = "lr"
        else:
            md_string = "CLUSTER\\_ZERO\\_MEM"
            inner_string = "{} ZERO MEMORY".format(entry['size'])
            cluster_string = ""
            cluster_border = "lrb"
            outer_end_addr = entry['end_addr_str']

        new_entry = {
            'quadrant_string':  quadrant_string,
            'quadrant_border':  quadrant_border,
            'cluster_string':   cluster_string,
            'cluster_border':   cluster_border,
            'inner_string':     inner_string,
            'inner_start_addr': entry['start_addr_str'],
            'inner_end_addr':   entry['end_addr_str'],
            'outer_start_addr': outer_start_addr,
            'outer_end_addr':   outer_end_addr
        }

        all_quadrant_entries_filled.append(new_entry)
        md_quadrants_list.append([
            qidx,
            cidx,
            md_string,
            entry['size'],
            new_entry['inner_start_addr'],
            new_entry['inner_end_addr'],
        ])

    # write out .tex file
    if tex_filename:
        write_template(tex_filename,
                       outdir,
                       all_entries=all_entries_filled,
                       nr_quadrants=NR_QUADRANTS,
                       nr_clusters=NR_CLUSTERS_PER_QUADRANT,
                       all_quadrant_entries=all_quadrant_entries_filled,
                       quadrant_filler=quadrant_filler)

    if md_filename:
        md_file_path = args.outdir / str(md_filename)

        md_quadrants_list.append([
            "-",
            "-",
            quadrant_filler['name'],
            quadrant_filler['size'],
            quadrant_filler['start_addr_str'],
            quadrant_filler['end_addr_str'],
        ])

        table_occamy_name = "Occamy Address Map"
        table_quadrants_name = "Quadrants Address Map"

        header_occamy = ["Name", "Size", "Status", "Start", "End"]
        header_quadrants = ["Quadrant", "Cluster", "Name", "Size", "Start", "End"]

        writer = MarkdownTableWriter(margin=1)

        with open(md_file_path, "w") as file:
            writer.stream = file

            # markdown text
            file.write("# Address Map")
            file.write("\n\n")
            file.write("This is the current address map of occamy. ")
            file.write("Note that the Quadrants address map has its own table below.")
            file.write("\n\n")

            # add occamy addrmap
            file.write("## " + table_occamy_name)
            file.write("\n\n")
            writer.headers = header_occamy
            writer.value_matrix = md_occamy_list

            # set style
            writer.set_style("Name", Style(align="left"))
            writer.set_style("Size", Style(align="right"))
            writer.set_style("Status", Style(align="center"))
            writer.set_style("Start", Style(align="right"))
            writer.set_style("End", Style(align="right"))

            writer.write_table()
            writer.write_null_line()
            writer.write_null_line()

            # add quadrants addrmap
            file.write("## " + table_quadrants_name)
            file.write("\n\n")
            writer.headers = header_quadrants
            writer.value_matrix = md_quadrants_list

            writer.set_style("Quadrant", Style(align="center"))
            writer.set_style("Cluster", Style(align="center"))
            writer.set_style("Name", Style(align="left"))
            writer.set_style("Size", Style(align="right"))
            writer.set_style("Start", Style(align="right"))
            writer.set_style("End", Style(align="right"))

            writer.write_table()
            writer.write_null_line()


if __name__ == "__main__":

    """Generate the memory map for a given memory address map."""
    parser = argparse.ArgumentParser(prog="addrmapgen")
    parser.add_argument("--file",
                        "-f",
                        metavar="file",
                        type=argparse.FileType('r'),
                        required=True,
                        help="A csv memory map file (input)")
    parser.add_argument("--outdir",
                        "-o",
                        type=pathlib.Path,
                        required=True,
                        help="Target directory.")
    parser.add_argument("--tex",
                        metavar="TEX_TEMPLATE",
                        type=str,
                        help="Name of the .tex template file (input)")
    parser.add_argument("--md",
                        metavar="MD_FILE",
                        type=str,
                        help="Name of the .md file (output)")

    args = parser.parse_args()

    main(file=args.file, outdir=args.outdir, tex_filename=args.tex, md_filename=args.md)
