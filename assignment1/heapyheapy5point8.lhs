\documentclass{article}
\usepackage{amsmath}
%include polycode.fmt
%format odot = "\odot "
%format leftChild = "\swarrow"
%format lw = "\langle"
%format rw = "\rangle"
\begin{document}

When $\odot$ stops recursing, it has gone through a prefix segment of cuts of a
tree with labels less than b.  The remaining cuts* are reduced using paste and
made the left child of $\langle b \rangle$.  This new cut is appended to the aforementioned
prefix segment.  This is, by the definitions of the prefix operators,
equivalent to the second definition of $\odot$.

> xs odot b = (pb `takePrefix` xs) ++ [paste (pb `dropPrefix` xs) leftChild lw b rw]

where

> pb (x leftChild lw a rw) = a < b

*Necessary for paste to be well-defined


By the prefix lemma, we infer a third definition of $\odot$:

> xs odot b = ((not . pb) `dropSuffix` xs) ++ [paste ((not . pb) `takeSuffix` xs) leftChild lw b rw]

During each application of $\odot$, the right spine of the proto-heap is
traversed from the bottom up.  Upon termination of the traversal (when the
label becomes less than b), the traversed nodes are removed from the spine and
placed as the left subtree under $\langle b \rangle$.  Therefore it is impossible for any node
to be visited more than once, so the total running time is linear with respect
to the final number of nodes.



\end{document}
