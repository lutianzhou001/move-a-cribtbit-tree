module my_first_package::hello_world {
    use std::string;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    //types
    struct HelloworldObject has key, store {
        id: UID,
        name: string::String,
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