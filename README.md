# AVL for maintaining the set of potentially non-dominated points

- This AVL type is derived from the AVL structure in DataStructures.jl.

- #### Copyright (c) 2021, DataStructures.jl. All rights reserved.
- #### https://github.com/JuliaCollections/DataStructures.jl

## How to use

1. Open Julia Repl : <code>& julia</code>

2. Import the code : <code>$ include("avl_ypn.jl")</code>

3. Create an empty AVL tree : <code>$ myTree = AVLTree()</code>

4. Insert a potentially non-dominated point <code>y::Tuple{Int,Int}</code> : <code>$ insert!(myTree,y)</code> Complexity : <code>O(log(n))</code>

5. Get a point using its index (starting from 1) : <code>$ myTree[index]</code> Complexity : <code>O(log(n))</code>

6. Return all the points in the tree as a sorted vector of <code>Tuple{Int,Int}</code> : <code>$ get_all_points(myTree)</code> Complexity : <code>O(n)</code>
