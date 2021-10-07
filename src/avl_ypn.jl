
# Copyright (c) 2021, DataStructures.jl. All rights reserved.
# https://github.com/JuliaCollections/DataStructures.jl

""" This file contains a type of AVL able to store potentially
non-dominated points for bi-objective problems. The intertion
function insert!(avl, (z1,z2)) stores the point in the tree and
proceeds in a fathoming test. Functions insert! and delete! have
been modified."""

""" This version of AVL only works with integers points. But is
1,3846 times faster in average. """

# it has unique keys
# leftChild has keys which are less than the node
# rightChild has keys which are greater than the node
# height stores the height of the subtree.
mutable struct AVLTreeNode
    height::Int8
    leftChild::Union{AVLTreeNode, Nothing}
    rightChild::Union{AVLTreeNode, Nothing}
    subsize::Int32
    data::Tuple{Int,Int}
end

AVLTreeNode(d::Tuple{Int,Int}) = AVLTreeNode(1, nothing, nothing, 1, d)

AVLTreeNode_or_null = Union{AVLTreeNode, Nothing}

mutable struct AVLTree
    root::AVLTreeNode_or_null
    count::Int
end

AVLTree() = AVLTree(nothing, 0)

Base.length(tree::AVLTree) = tree.count

get_height(node::Union{AVLTreeNode, Nothing}) = (node == nothing) ? 0 : node.height

# balance is the difference of height between leftChild and rightChild of a node.
function get_balance(node::Union{AVLTreeNode, Nothing})
    if node == nothing
        return 0
    else
        return get_height(node.leftChild) - get_height(node.rightChild)
    end
end

# computes the height of the subtree, which basically is
# one added the maximum of the height of the left subtree and right subtree
compute_height(node::AVLTreeNode) = 1 + max(get_height(node.leftChild), get_height(node.rightChild))

get_subsize(node::AVLTreeNode_or_null) = (node == nothing) ? 0 : node.subsize

# compute the subtree size
function compute_subtree_size(node::AVLTreeNode_or_null)
    if node == nothing
        return 0
    else
        L = get_subsize(node.leftChild)
        R = get_subsize(node.rightChild)
        return (L + R + 1)
    end
end

"""
    left_rotate(node_x::AVLTreeNode)
Performs a left-rotation on `node_x`, updates height of the nodes, and returns the rotated node. 
"""
function left_rotate(z::AVLTreeNode)
    y = z.rightChild
    α = y.leftChild
    y.leftChild = z
    z.rightChild = α
    z.height = compute_height(z)
    y.height = compute_height(y)
    z.subsize = compute_subtree_size(z)
    y.subsize = compute_subtree_size(y)
    return y
end

"""
    right_rotate(node_x::AVLTreeNode)
Performs a right-rotation on `node_x`, updates height of the nodes, and returns the rotated node. 
"""
function right_rotate(z::AVLTreeNode)
    y = z.leftChild
    α = y.rightChild
    y.rightChild = z
    z.leftChild = α
    z.height = compute_height(z)
    y.height = compute_height(y)
    z.subsize = compute_subtree_size(z)
    y.subsize = compute_subtree_size(y)
    return y
end

"""
   minimum_node(tree::AVLTree, node::AVLTreeNode) 
Returns the AVLTreeNode with minimum value in subtree of `node`. 
"""
function minimum_node(node::Union{AVLTreeNode, Nothing})
    while node != nothing && node.leftChild != nothing
        node = node.leftChild
    end
    return node
end

function search_node(tree::AVLTree, d::Tuple{Int,Int})
    prev = nothing
    node = tree.root
    while node != nothing && node.data != nothing && node.data != d

        prev = node
        if d < node.data 
            node = node.leftChild
        else
            node = node.rightChild
        end
    end
    
    return (node == nothing) ? prev : node
end

function Base.haskey(tree::AVLTree, d::Tuple{Int,Int})
    (tree.root == nothing) && return false
    node = search_node(tree, d)
    return (node.data == d)
end

Base.in(key, tree::AVLTree) = haskey(tree, key)


function Base.insert!(tree::AVLTree, d::Tuple{Int,Int})

    # Return the new root of the tree after inserting the given node,
    # and the difference in terms of number of nodes in the tree (delta).
    # delta_rec denotes the difference in terms of nb of nodes already made
    # during the global computation.
    function insert_node(node::Union{AVLTreeNode, Nothing}, value_to_insert; delta_rec = 0, space = " >")
        
        if node == nothing
            return AVLTreeNode(value_to_insert), delta_rec + 1
        end
        
        (z1,z2) = value_to_insert
        (z1_node,z2_node) = node.data

        # STOP : the new node is dominated
        if z1 >= z1_node && z2 >= z2_node
            return node, delta_rec # we don't insert the node, no change on delta
        # NO STOP : the new node dominates the current node
        elseif (z1 <= z1_node && z2 <= z2_node) && (z1 < z1_node || z2 < z2_node)
            node, value_inserted = delete_root(node,value_to_insert)
            if !value_inserted # value hasn't been inserted yet
                node, delta = insert_node(node, value_to_insert, delta_rec = delta_rec-1, space = string(space," >"))
            else
                delta = delta_rec # we have replaced one node with another
            end
        # NO STOP : the new node is in the left subtree
        elseif value_to_insert < node.data
            node.leftChild, delta = insert_node(node.leftChild, value_to_insert, delta_rec = delta_rec, space = string(space," >"))
        # NO STOP : the new node is on the right subtree
        else
            node.rightChild, delta = insert_node(node.rightChild, value_to_insert, delta_rec = delta_rec, space = string(space," >"))
        end

        # in this part of the code, the value has been inserted in the tree
        
        node.subsize = compute_subtree_size(node)
        node.height = compute_height(node)
        balance = get_balance(node)
        
        if balance > 1
            if value_to_insert < node.leftChild.data
                return right_rotate(node), delta
            else
                node.leftChild = left_rotate(node.leftChild)
                return right_rotate(node), delta
            end
        end

        if balance < -1
            if value_to_insert > node.rightChild.data
                return left_rotate(node), delta
            else
                node.rightChild = right_rotate(node.rightChild)
                return left_rotate(node), delta
            end
        end

        return node, delta
    end

    # Delete the root node and return the new root node
    # Return also true if the given value has been inserted inside
    # the subtree, or not.
    function delete_root(node::Union{AVLTreeNode, Nothing}, value_to_insert)
        # no children at all, replace the data and return the same node
        if node.leftChild == nothing && node.rightChild == nothing
            node.data = value_to_insert
            return node, true # the value has been inserted
        # no left child but a right child, replace the root by the right child
        elseif node.leftChild == nothing
            result = node.rightChild
            return result, false # the value hasn't been inserted
        # no right child but a left child, replace the root by the left child
        elseif node.rightChild == nothing
            result = node.leftChild
            return result, false # the value hasn't been inserted
        # both children, replace the root by minimum node of the right subtree
        # and delete the minimum node from the subtree (usual method for AVL)
        else
            result = minimum_node(node.rightChild)
            node.data = result.data
            node.rightChild = delete_node!(node.rightChild, result.data)
        end

        node.subsize = compute_subtree_size(node)
        node.height = compute_height(node)
        balance = get_balance(node)

        if balance > 1
            if get_balance(node.leftChild) >= 0
                return right_rotate(node), false
            else
                node.leftChild = left_rotate(node.leftChild)
                return right_rotate(node), false
            end
        end

        if balance < -1
            if get_balance(node.rightChild) <= 0
                return left_rotate(node), false
            else
                node.rightChild = right_rotate(node.rightChild)
                return left_rotate(node), false
            end
        end 
        
        return node, false # current root node, value_inserted
    end

    function delete_node!(node::Union{AVLTreeNode, Nothing}, key)
        if key < node.data
            node.leftChild = delete_node!(node.leftChild, key)
        elseif key > node.data
            node.rightChild = delete_node!(node.rightChild, key)
        else
            if node.leftChild == nothing
                result = node.rightChild
                return result
            elseif node.rightChild == nothing
                result = node.leftChild
                return result
            else
                result = minimum_node(node.rightChild)
                node.data = result.data
                node.rightChild = delete_node!(node.rightChild, result.data)
            end
        end
        
        node.subsize = compute_subtree_size(node)
        node.height = compute_height(node)
        balance = get_balance(node)

        if balance > 1
            if get_balance(node.leftChild) >= 0
                return right_rotate(node)
            else
                node.leftChild = left_rotate(node.leftChild)
                return right_rotate(node)
            end
        end

        if balance < -1
            if get_balance(node.rightChild) <= 0
                return left_rotate(node)
            else
                node.rightChild = right_rotate(node.rightChild)
                return left_rotate(node)
            end
        end 
        
        return node
    end

    haskey(tree, d) && return tree

    tree.root, delta = insert_node(tree.root, d)

    tree.count += delta

    return tree
end

function Base.push!(tree::AVLTree, key0)
    key = convert(Tuple{Int,Int}, key0)
    insert!(tree, key)
end

function Base.delete!(tree::AVLTree, d::Tuple{Int,Int})

    function delete_node!(node::Union{AVLTreeNode, Nothing}, key)
        if key < node.data
            node.leftChild = delete_node!(node.leftChild, key)
        elseif key > node.data
            node.rightChild = delete_node!(node.rightChild, key)
        else
            if node.leftChild == nothing
                result = node.rightChild
                return result
            elseif node.rightChild == nothing
                result = node.leftChild
                return result
            else
                result = minimum_node(node.rightChild)
                node.data = result.data
                node.rightChild = delete_node!(node.rightChild, result.data)
            end
        end
        
        node.subsize = compute_subtree_size(node)
        node.height = compute_height(node)
        balance = get_balance(node)

        if balance > 1
            if get_balance(node.leftChild) >= 0
                return right_rotate(node)
            else
                node.leftChild = left_rotate(node.leftChild)
                return right_rotate(node)
            end
        end

        if balance < -1
            if get_balance(node.rightChild) <= 0
                return left_rotate(node)
            else
                node.rightChild = right_rotate(node.rightChild)
                return left_rotate(node)
            end
        end
        
        return node
    end

    # if the key is not in the tree, do nothing and return the tree
    !haskey(tree, d) && return tree
    
    # if the key is present, delete it from the tree
    tree.root = delete_node!(tree.root, d)
    tree.count -= 1
    return tree
end

"""
    sorted_rank(tree::AVLTree, key)
Returns the rank of `key` present in the `tree`, if it present. A KeyError is thrown if `key` is not present.
"""
function sorted_rank(tree::AVLTree, key::Tuple{Int,Int})
    !haskey(tree, key) && throw(KeyError(key))
    node = tree.root
    rank = 0
    while node.data != key
        if (node.data < key)
            rank += (1 + get_subsize(node.leftChild))
            node = node.rightChild
        else
            node = node.leftChild
        end
    end 
    rank += (1 + get_subsize(node.leftChild))
    return rank
end

function Base.getindex(tree::AVLTree, ind::Integer) # O(log(n))
    @boundscheck (1 <= ind <= tree.count) || throw(BoundsError("$ind should be in between 1 and $(tree.count)"))
    function traverse_tree(node::AVLTreeNode_or_null, idx)
        if (node != nothing)
            L = get_subsize(node.leftChild)
            if idx <= L
                return traverse_tree(node.leftChild, idx)
            elseif idx == L + 1
                return node.data
            else
                return traverse_tree(node.rightChild, idx - L - 1)
            end
        end
    end
    value = traverse_tree(tree.root, ind) 
    return value
end

# return a vector of points sorted with regards to the first objective
function get_all_points(tree::AVLTree) # O(n)
    points = Vector{Tuple{Int,Int}}(undef,tree.count)
    index = 1

    function inorder_traverse(node::AVLTreeNode_or_null, points::Vector{Tuple{Int,Int}}, index::Int)
        if node == nothing
            return index
        else
            index = inorder_traverse(node.leftChild, points, index)
            points[index] = node.data
            index += 1
            index = inorder_traverse(node.rightChild, points, index)
            return index
        end
    end

    inorder_traverse(tree.root,points,index)

    return points
end

# generic preorder traverse of the tree
# f :: function to apply to the node.data
# aux :: embeded information
# g :: function updating aux during the traverse
# example : Print the nodes values and count their number ->
# traverse_preorder(
#    tree,
#    println,
#    function g(aux) = aux + 1,
#    0)
function traverse_preorder(tree::AVLTree, f, g, aux)
    function traverse_preorder(node::AVLTreeNode_or_null, f, g, aux)
        if node == nothing
            return aux
        else
            f(node.data)
            aux = g(aux)
            aux = traverse_preorder(node.leftChild, f, g, aux)
            aux = traverse_preorder(node.rightChild, f, g, aux)
            return aux
        end
    end

    traverse_preorder(tree.root,f, g, aux)
end

# generic inorder traverse of the tree
function traverse_inorder(tree::AVLTree, f, g, aux)
    function traverse_inorder(node::AVLTreeNode_or_null, f, g, aux)
        if node == nothing
            return aux
        else
            aux = traverse_inorder(node.leftChild, f, g, aux)
            f(node.data)
            aux = g(aux)
            aux = traverse_inorder(node.rightChild, f, g, aux)
            return aux
        end
    end

    traverse_inorder(tree.root,f, g, aux)
end

# generic postorder traverse of the tree
function traverse_postorder(tree::AVLTree, f, g, aux)
    function traverse_postorder(node::AVLTreeNode_or_null, f, g, aux)
        if node == nothing
            return aux
        else
            aux = traverse_postorder(node.leftChild, f, g, aux)
            aux = traverse_postorder(node.rightChild, f, g, aux)
            f(node.data)
            aux = g(aux)
            return aux
        end
    end

    traverse_postorder(tree.root,f, g, aux)
end