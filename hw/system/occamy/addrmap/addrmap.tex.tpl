<%text>
% Copyright 2020 ETH Zurich and University of Bologna.
% Licensed under the Apache License, Version 2.0, see LICENSE for details.
% SPDX-License-Identifier: Apache-2.0
</%text>

\documentclass[]{standalone}

\usepackage[]{bytefield}

\begin{document}

\bytefieldsetup{bitheight=2\baselineskip}%
{\tiny

  \begin{bytefield}[bitheight=2\baselineskip]{19}

  % for i in all_entries:
    % if i['name'] == 'EMPTY': 
    \bytefieldsetup{bitheight=1.4\baselineskip}%
    \bitbox[]{5}{} & 
    \bitbox{14}{${i['size']} ${i['name']}} \\\
    \bytefieldsetup{bitheight=2\baselineskip}%

    % else:
    \bitbox[]{5}{\texttt{${i['start_addr_str']}} \\ [0\baselineskip] \texttt{${i['end_addr_str']}}} &
    \bitbox{14}{${i['size']} for ${i['name']}} \\\

    % endif
  %endfor

  \end{bytefield}



  \begin{bytefield}[]{26}
  % for entry in all_quadrant_entries:

    \bytefieldsetup{bitheight=2\baselineskip}%
    \bitbox[]{4}{\texttt{${entry['outer_start_addr']}} \\ [0\baselineskip] \texttt{${entry['outer_end_addr']}}} &
    \bitbox[${entry['quadrant_border']}]{5}{\texttt{${entry['quadrant_string']}}} &
    \bitbox[${entry['cluster_border']}]{5}{\texttt{${entry['cluster_string']}}} &
    \bitbox{8}{\texttt{${entry['inner_string']}}} &
    \bitbox[]{4}{\texttt{${entry['inner_start_addr']}} \\ [0\baselineskip] \texttt{${entry['inner_end_addr']}}} \\\

  %endfor

    \bytefieldsetup{bitheight=2\baselineskip}%
    \bitbox[]{4}{\texttt{${quadrant_filler['start_addr_str']}} \\ [0\baselineskip] \texttt{${quadrant_filler['end_addr_str']}}} &
    \bitbox{18}{${quadrant_filler['size']} ${quadrant_filler['name']}} &
    \bitbox[]{4}{\texttt{${quadrant_filler['start_addr_str']}} \\ [0\baselineskip] \texttt{${quadrant_filler['end_addr_str']}}}  \\\

  \end{bytefield}

}

\end{document}