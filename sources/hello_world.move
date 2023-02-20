module my_first_package::critbit {
    use sui::object::{Self, UID};
    use sui::vec_map::{Self, VecMap, insert, remove, get, get_mut};
    use sui::tx_context::{Self, TxContext};
    use std::option::{Self, Option, is_some, extract};
    use std::vector::{
        borrow_mut as v_b_m,
        borrow as v_b,
    };

    struct CTree<V> {
        root: u64,
        nodes:VecMap<Option<u64>,Node<V>>,
    }
    
    // max of depth is 63 in a u64 number.
    const MAX_DEPTH: u8 = 63;

    struct Node<V> has key, copy, store {
        depth: u8,
        // only leaf have the key and the value, while only node have the children.
        key: Option<u64>,
        value: Option<V>,
        parentKey: Option<u64>,
        leftChildIdx: Option<u64>,
        rightChildIdx: Option<u64>,
    }

    public fun min_leaf<V: key + copy>(cTree: &CTree<V>) : (Option<u64>, Option<V>) {
        // we try to find the min leaf in the tree with the binary tree search algorithm.
        let node = get<Option<u64>, Node<V>>(&cTree.nodes, &option::some(cTree.root));
        let depth = 0;
        loop {
            if (is_some(&node.value)) {
                // in this case, we find the leaf;
                return (node.key, option::some(*option::borrow(&node.value)));
            } else {
                // otherwise, we find a node;
                if (is_some(&node.leftChildIdx)) {
                    let node = get<Option<u64>, Node<V>>(&cTree.nodes, &node.leftChildIdx);
                } else if (is_some(&node.rightChildIdx)) {
                    let node = get<Option<u64>, Node<V>>(&cTree.nodes, &node.rightChildIdx);
                } else {
                // the node does not have a left child nor have a right child, return null.
                return (option::none(), option::none());
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

    public fun insert_leaf<V>(
        cTree: &mut CTree<V>,
        key: u64,
        value: V
    ): &mut Node<V> {
        // if it is not the leaf, it must be a node, borrow_mut the node
        let node = get_mut<Option<u64>, Node<V>>(&mut cTree.nodes, &option::some(cTree.root));
        let depth:u8 = 0;
        loop {
            if (key >> (MAX_DEPTH - depth) & 1 == 1) {
                // dispose of right child or right leaf.
                let parentKey = cal_vec_map_key(key >> (MAX_DEPTH - depth + 1), depth -1);
                let currentKey = cal_vec_map_key(key >> (MAX_DEPTH - depth), depth);
                if (depth == MAX_DEPTH) {
                    // it must be a leaf, append a leaf on the bottom of the tree.
                    insert<Option<u64>, Node<V>>(&mut cTree.nodes, option::some(key), Node<V>{
                        depth: MAX_DEPTH,
                        key: option::some(key),
                        value: option::some(value),
                        parentKey: option::some(parentKey),
                        leftChildIdx: option::none(),
                        rightChildIdx: option::none(),
                    });
                    node.rightChildIdx = option::some(key);
                } else {
                    // bit at that == 1, it have to deep to the right child.
                    if (is_some(&node.rightChildIdx)) {
                        node = get_mut<Option<u64>,Node<V>>(&mut cTree.nodes, &node.rightChildIdx);
                    } else {
                        // create a new node here.
                        insert<Option<u64>,Node<V>>(&mut cTree.nodes, option::some(currentKey), Node<V>{
                            depth,
                            key: option::none(),
                            value: option::none(),
                            parentKey: option::some(parentKey),
                            leftChildIdx: option::none(),
                            rightChildIdx: option::none(),
                        });
                        // append the right child to the node
                        node.rightChildIdx = option::some(currentKey);
                    }
                }
            } else {
                // dispose of left child or left leaf.
                let parentKey = cal_vec_map_key(key >> (MAX_DEPTH - depth + 1), depth -1);
                let currentKey = cal_vec_map_key(key >> (MAX_DEPTH - depth), depth);
                if (depth == MAX_DEPTH) {
                    // it must be a leaf, we just set the child to none.
                    insert<Option<u64>, Node<V>>(&mut cTree.nodes, option::some(key), Node<V>{
                        depth: MAX_DEPTH,
                        key: option::some(key),
                        value: option::some(value),
                        parentKey: option::some(parentKey),
                        leftChildIdx: option::none(),
                        rightChildIdx: option::none(),
                    });
                    node.leftChildIdx = option::some(key);
                } else {
                    // bit == 0, consider the left child.
                    if (is_some(&node.leftChildIdx)) {
                        node = get_mut<Option<u64>, Node<V>>(&mut cTree.nodes, &node.leftChildIdx);
                    } else {
                        insert<Option<u64>,Node<V>>(&mut cTree.nodes, option::some(currentKey), Node<V>{
                            depth,
                            key: option::none(),
                            value: option::none(),
                            parentKey: option::some(parentKey),
                            leftChildIdx: option::none(),
                            rightChildIdx: option::none(),
                        });
                        // append the left child to the node
                        node.leftChildIdx = option::some(currentKey)
                    }
                }
            };
            depth = depth + 1;
        }
    }

    public fun bit_at(key: u64, bit: u8) : bool {
        (key >> bit) & 1 == 1
    }

    public fun remove_leaf<V: copy>(cTree: &mut CTree<V>, key: u64) {
        let node = get_mut<Option<u64>, Node<V>>(&mut cTree.nodes, &option::some(cTree.root));
        let depth = 0;
        loop {
            if ((key >> (MAX_DEPTH - depth) & 1 == 1)) {
                // we dispose of the right child or right leaf.
                if (depth == MAX_DEPTH) {
                    // we will remove the leaf here: the right child
                    node.rightChildIdx = option::none();
                    remove<Option<u64>, Node<V>>(&mut cTree.nodes, &node.rightChildIdx);
                } else {
                    // route to the node
                    if (is_some(&node.rightChildIdx)) {
                        node = get_mut<Option<u64>, Node<V>>(&mut cTree.nodes, &node.rightChildIdx);
                    } else {
                        break;
                    }
                }
            } else {
                if (depth == MAX_DEPTH) {
                    // we will remove the leaf here: the left child
                    node.leftChildIdx = option::none();
                    remove<Option<u64>, Node<V>>(&mut cTree.nodes, &node.leftChildIdx);
                } else {
                    // route the node
                    if (is_some(&node.leftChildIdx)) {
                        node =get_mut<Option<u64>, Node<V>>(&mut cTree.nodes, &node.leftChildIdx);
                    } else {
                        break;
                    }
                }
            };
            depth = depth + 1;
        }
    }

    //functions
    public entry fun mint(ctx: &mut TxContext) {}
}