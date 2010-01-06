#!/bin/bash

cat <<EoF > /tmp/test.tex
\documentclass[12pt]{article}

\usepackage[parmaite]{tengwarscript}

\begin{document}

$(./enc.rb)

\end{document}

EoF


