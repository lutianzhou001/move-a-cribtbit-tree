module moveX::critbit {
    use sui::object::{Self, ID, UID};
    use sui::vec_map::{Self, VecMap, insert, remove, get, get_mut};
    use sui::tx_context::TxContext;
    use std::option::{Self, Option, is_some};

    struct CTree<V> {
        root: u64,
        nodes:VecMap<Option<u64>,Node<V>>,
    }
    
    // max of depth is 63 in a u64 number.
    const MAX_DEPTH: u8 = 63;

    struct Node<V> has key, store {
        // actually the sui needs an id to identify the object and the id donot have the drop, so we need to make full use of it.
        id: UID,
        depth: u8,
        // only leaf have the key and the value, while only node have the children.
        key: Option<u64>, // only leaf have the key
        value: Option<V>, // only leaf have the value
        parentKey: Option<u64>, // both leaves and nodes have the parentKey
        leftChildIdx: Option<u64>, // only node have the leftChildIdx
        rightChildIdx: Option<u64>, // only node have the rightChildIdx
    }

    public fun next_leaf<V: key + copy>(cTree: &CTree<V>, key:u64) : (Option<u64>, Option<V>) {
        // find the next_leaf with the front-order binary search algorithm.
        // first get the ref of the very node.
        let node = get<Option<u64>, Node<V>>(&cTree.nodes, &option::some(key));
        if (is_some(&node.leftChildIdx)) {
            // resursive to search the left child.
            next_leaf(cTree, *option::borrow(&node.leftChildIdx))
        } else if (is_some(&node.rightChildIdx)){
            // resursive to search the right child.
            next_leaf(cTree, *option::borrow(&node.rightChildIdx))
        } else if (is_some(&node.value)) {
            // if this node does not have a left child nor have a right child, and it has the value,
            // it is the very leaf we want to find.
            return (node.key, option::some(*option::borrow(&node.value)))
        } else {
            // if this node does not have a left child nor have a right child, and it does not have the value,
            // it is a node, we need to find the next leaf.
            next_leaf(cTree, *option::borrow(&node.parentKey))
        }
    }

    public fun min_leaf<V: key + copy>(cTree: &CTree<V>) : (Option<u64>, Option<V>) {
        // we try to find the min leaf in the tree with the binary tree search algorithm.
        let node = get<Option<u64>, Node<V>>(&cTree.nodes, &option::some(cTree.root));
        loop {
            if (is_some(&node.value)) {
                // in this case, we find the leaf;
                return (node.key, option::some(*option::borrow(&node.value)))
            } else {
                // otherwise, we find a node;
                if (is_some(&node.leftChildIdx)) {
                    node = get<Option<u64>, Node<V>>(&cTree.nodes, &node.leftChildIdx);
                } else if (is_some(&node.rightChildIdx)) {
                    node = get<Option<u64>, Node<V>>(&cTree.nodes, &node.rightChildIdx);
                } else {
                // the node does not have a left child nor have a right child, return null.
                return (option::none(), option::none())
                }
            }
        }
    }

    /// key to the vec_set key
    /// in the 'depth'th of the tree, numbers range from 2^depth -1 to 2^(depth+1) - 2
    /// offset is the key, so the vec_set key is 2^depth -1 + key.
    public fun cal_vec_map_key(key: u64, depth: u8) : u64 {
        let x = 1;
        while (depth > 0) {
            x = x * 2;
            depth = depth - 1;
        };
        return x - 1 + key
    }

    public fun insert_leaf<V: drop>(
        cTree: &mut CTree<V>,
        key: u64,
        value: V,
        ctx: &mut TxContext
     ) {
        let (depth, parentKey, key, isRightChild, _) = locate(cTree, key);
        if (depth == MAX_DEPTH) {
            // insert a leaf
            insert<Option<u64>, Node<V>>(&mut cTree.nodes, option::some(key), Node<V>{
                id: object::new(ctx),
                depth: MAX_DEPTH,
                key: option::some(key),
                value: option::some(value),
                parentKey: option::some(parentKey),
                leftChildIdx: option::none(),
                rightChildIdx: option::none(),
            });
            let node = get_mut<Option<u64>, Node<V>>(&mut cTree.nodes, &option::some(key));
            if (isRightChild) {
                node.rightChildIdx = option::some(key);
            } else {
                node.leftChildIdx = option::some(key);
            }
        } else {
            // insert a node
            insert<Option<u64>, Node<V>>(&mut cTree.nodes, option::some(key), Node<V>{
                id: object:: new(ctx),
                depth,
                key: option::none(),
                value: option::none(),
                parentKey: option::some(parentKey),
                leftChildIdx: option::none(),
                rightChildIdx: option::none(),
            });
            let node = get_mut<Option<u64>, Node<V>>(&mut cTree.nodes, &option::some(parentKey));
            if (isRightChild) {
                node.rightChildIdx = option::some(key);
            } else {
                node.leftChildIdx = option::some(key);
            }
        }
    }

    public fun locate<V>(
        cTree: &CTree<V>,
        key: u64,
    ): (u8, u64, u64, bool, bool) {
        // if it is not the leaf, it must be a node, borrow_mut the node
        let node = get<Option<u64>, Node<V>>(&cTree.nodes, &option::some(cTree.root));
        let depth:u8 = 0;
        loop {
            if (key >> (MAX_DEPTH - depth) & 1 == 1) {
                // dispose of right child or right leaf.
                let parentKey = cal_vec_map_key(key >> (MAX_DEPTH - depth + 1), depth -1);
                let currentKey = cal_vec_map_key(key >> (MAX_DEPTH - depth), depth);
                if (depth == MAX_DEPTH) {
                    // it must be a leaf, append a leaf on the bottom of the tree.
                    return (depth, parentKey, key, true, true)
                } else {
                    // bit at that == 1, it have to deep to the right child.
                    if (is_some(&node.rightChildIdx)) {
                        node = get<Option<u64>,Node<V>>(&cTree.nodes, &node.rightChildIdx);
                    } else {
                        return (depth, parentKey, currentKey, true, false)
                    }
                }
            } else {
                // dispose of left child or left leaf.
                let parentKey = cal_vec_map_key(key >> (MAX_DEPTH - depth + 1), depth -1);
                let currentKey = cal_vec_map_key(key >> (MAX_DEPTH - depth), depth);
                if (depth == MAX_DEPTH) {
                    return (depth, parentKey, key, false, true)
                } else {
                    // bit == 0, consider the left child.
                    if (is_some(&node.leftChildIdx)) {
                        node = get<Option<u64>, Node<V>>(&cTree.nodes, &node.leftChildIdx);
                    } else {
                        return (depth, parentKey, currentKey, false, false)
                    }
                }
            };
            depth = depth + 1;
        }
    }

    public fun bit_at(key: u64, bit: u8) : bool {
        (key >> bit) & 1 == 1
    }

    public fun remove_leaf<V: copy>(cTree: &mut CTree<V>, key: u64): Option<Node<V>> {
        let (_, _, key, _, isLeaf) = locate(cTree, key);
        // if it is a leaf, we will remove it. else, we cannot find the leaf.
        if (isLeaf == true) {
            let (_,v) = remove<Option<u64>, Node<V>>(&mut cTree.nodes, &option::some(key));
            return option::some(v)
        };
        // else, we cannot find the leaf. so we return a option::none() to the caller.
        return option::none()
    }

    //functions
    public entry fun main() {}
}