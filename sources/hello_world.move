module my_first_package::critbit {
    use std::string;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::option::{Self, Option, is_some, extract};
    use std::vector::{
        length,
        is_empty,
        borrow_mut as v_b_m,
        borrow as v_b,
        push_back as v_p_b,
    };
    use sui::validator::Validator;
    use sui::immutable_external_resource;


    //types
    struct HelloworldObject has key, store {
        id: UID,
        name: string::String,
    }

    struct CTree<V> {
        root: u64,
        leaves: vector<Leaf<V>>,
        nodes: vector<Node>,
    }
    
    // max of depth is 63 in a u64 number.
    const MAX_DEPTH: u8 = 63;

    struct Leaf<V> has key, copy, store {
        key: u64,
        value: V,
        parentNodeIdx: u64,
    }

    struct Node has key, copy, store {
        depth: u8,
        key: u64,
        parentNodeIdx: u64,
        leftChildIdx: Option<u64>,
        rightChildIdx: Option<u64>,
    }

    public fun getLenght<V>(cTree: &CTree<V>): u64 {
        length<Leaf<V>>(&cTree.leaves)
    }
    
    public fun min_leaf<V>(cTree: &CTree<V>) : (u64, V) {
        // we try to find the min leaf in the tree with the binary tree search algorithm.
        let node = v_b<Node>(&cTree.nodes, cTree.root);
        let depth = 0;
        loop {
            if (depth == MAX_DEPTH) {
                if (is_some(&node.leftChildIdx)) {
                    // it must be a leaf, return the leaf
                    let leaf = v_b<Leaf<V>>(&cTree.leaves, extract(node.leftChildIdx));
                    return (leaf.key, leaf.value);
                } else {
                    // it must be that min leaf, just return the leaf
                    let leaf = v_b<Leaf<V>>(&cTree.leaves, extract(node.rightChildIdx));
                    return (leaf.key, leaf.value);
                }
            } else {
                if (is_some(&node.leftChildIdx)) {
                    node = v_b<Node>(&cTree.nodes, extract(node.leftChildIdx));
                } else {
                    // it must be a leaf, return the leaf
                    let node = v_b<Node>(&cTree.leaves, extract(node.rightChildIdx));
                }
            };
            depth = depth + 1;
        }
    }

    fun insert_leaf<V>(
        cTree: &mut CTree<V>,
        key: u128,
        value: V
    ): &mut Node {
        // if it is not the leaf, it must be a node, borrow_mut the node
        let node = v_b<Node>(&cTree.nodes, cTree.root);
        let depth = 0;
        loop {
            if ((key >> (MAX_DEPTH - depth) && 1 == 1)) {
                if (depth == MAX_DEPTH) {
                    // it must be a leaf, append a leaf on the bottom of the tree.
                    v_p_b<Leaf<V>>(&mut cTree.leaves, Leaf{
                        key,
                        value,
                        parentNodeIdx: cTree.root,
                    });
                    node.rightChildIdx = key;
                } else {
                    if (is_some(&node.rightChildIdx)) {
                        node = v_b<Node>(&cTree.nodes, extract(node.rightChildIdx));
                    } else {
                        let idx = key >> (MAX_DEPTH - depth) << 1 + 1;
                        // create a new node here.
                        v_p_b<Node>(&mut cTree.nodes, Node {
                            depth,
                            key: idx,
                            parentNodeIdx: node.key,
                            leftChildIdx: option::none<u64>,
                            rightChildIdx: option::none<u64>,
                        });
                        // append the right child to the node
                        node.rightChildIdx = idx;
                    }
                }
            } else {
                if (depth == MAX_DEPTH) {
                    // it must be a leaf, we just set the child to none.
                    v_p_b<Leaf<V>>(&mut cTree.leaves, Leaf{
                        key,
                        value,
                        parentNodeIdx: cTree.root,
                    });
                    node.rightChildIdx = key;
                } else {
                    if (is_some(node.leftChildIdx)) {
                        node = v_b<Node>(&cTree.nodes, extract(node.leftChildIdx));
                    } else {
                        let idx = key >> depth << 1 + 0;
                        // create a new node here
                        v_p_b<Node>(&mut cTree.nodes, Node {
                            depth,
                            key: idx,
                            parentNodeIdx: node.key,
                            leftChildIdx: option::none<u64>,
                            rightChildIdx: option::none<u64>,
                        });
                        // append the left child to the node
                        node.leftChildIdx = idx;
                    }
                }
            };
            depth = depth + 1;
        }
    }

    public fun bit_at(key: u64, bit: u8) : bool {
        (key >> bit) & 1 == 1
    }

    public fun remove_leaf<V>(cTree: &mut CTree<V>, key: u64): V {
        let node = v_b<Node>(&cTree.nodes, cTree.root);
        let depth = 0;
        loop {
            if ((key >> (MAX_DEPTH - depth) && 1 == 1)) {
                if (depth == MAX_DEPTH) {
                    // we will remove the leaf here: the right child
                    node.rightChildIdx = option::none<u64>;
                } else {
                    // route the node
                    if (is_some(node.rightChildIdx)) {
                        node = v_b<Node>(&cTree.nodes, node.rightChildIdx);
                    } else {
                        break;
                    }
                }
            } else {
                if (depth == MAX_DEPTH) {
                    // we will remove the leaf here: the left child
                    node.leftChildIdx = option::none<u64>;
                } else {
                    // route the node
                    if (is_some(node.leftChildIdx)) {
                        node = v_b<Node>(&cTree.nodes, node.leftChildIdx);
                    } else {
                        break;
                    }
                }
            };
            depth = depth + 1;
        }
    }

    //functions
    public entry fun mint(ctx: &mut TxContext) {
        let object = HelloworldObject {
            id: object::new(ctx),
            name: string::utf8(b"Hello world!")
        };
        transfer::transfer(object, tx_context::sender(ctx))
    }
}