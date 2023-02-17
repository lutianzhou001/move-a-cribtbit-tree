module my_first_package::critbit {
    use std::string;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::option::{Self, Option};
    use std::vector::{length, is_empty};


    //types
    struct HelloworldObject has key, store {
        id: UID,
        name: string::String,
    }

    struct CTree<V> {
        root: u64,
        leaves: Vec<Leaf<V>>,
        nodes: Vec<Node>,
    }
    
    // max of depth is 63 in a u64 number.
    const DEPTH: u8 = 63;

    struct Leaf<V> {
        key: u64,
        value: V,
        parentNodeIdx: u64,
    }

    struct Node {
        parentNodeIdx: u64,
        leftChildIdx: u64,
        rightChildIdx: u64,
    }

    public fun getLenght<V>(cTree: &CTree<V>): u64 {
        length<Leaf<V>>(&cTree.leaves)
    }
    
    fun is_node<>

    fun is_node(k: u64): bool {
        if k >> DEPTH 
        (i >> N_TYPE & OUT == OUT)}


    fun min_leaf<V>(
        cb: &CB<V>
    ): u64 {
        let node = cb.root; // Initialize index of search node to root
        loop {
            // If search node is an outer node return its field index
            if (is_out(i_n)) return i_n;
            i_n = v_b<I>(&cb.i, i_n).l // Review node's left child next
        }
    }

    const DEPTH : u8 = 8;

    public fun min_leaf(tree: &CTree<V>) : (u64, V) {
        if (option::is_none(tree.left) && option::is_none(tree.right)) {
            return (tree.key, tree.value);
        };
        if (option::is_some(tree.left)) {
            min_leaf(tree.left)
        };
        if (option::is_some(tree.right)) {
            min_leaf(tree.right)
        };
    }

    public fun contains(tree: &CTree, key: u64, depth: u8) : (bool, &CTree, u8) {
        while (depth > 0) {
            if (bit_at(key, depth)) {
                if (tree.left) {
                    node = tree.left;
                } else {
                    break;
                };
            } else {
                if (tree.right) {
                    node = tree.right;
                } else {
                    break;
                };
                node = tree.right;
            };
            depth = depth - 1;
        };
        if (depth > 0) {
            return (false, *node, depth);
        } else {
            return (true, *node, depth);
        }
    }

    public fun insert_leaf(tree: &mut CritbitTree<V>, key: u64, value: V) {
        let (contains, node, depth) = contains(tree, key, DEPTH);
        if (!contains) {
            while (depth > 0) {
                if (bit_at(key, depth)) {
                    node.left = CTree { key: key>>depth<<depth, value: V, left: 0, right: 0 };
                    node = node.left;
                } else {
                    node.right = CTree { key: key>>depth<<depth, value: V, left: 0, right: 0 };
                    node = node.right;
                };
                depth = depth - 1;
            }
        };
    }

    fun bit_at(key: u64, bit: u64) : bool {
        (key >> bit) & 1 == 1
    }
    
    public fun new():CritbitTree<V> {
        CritbitTree {
            root: 0,
            leaves: Vec::new(),
        }
    }

    public fun remove_leaf(tree: &mut CritbitTree<V>, key: u64) {
        let (contains, node, depth) = contains(tree, key, DEPTH-1);
        if (contains) {
            if (bit_at(key, depth)) {
                node.left = option::none();
            } else {
                node.right = option::none();
            };
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