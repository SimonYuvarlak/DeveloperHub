module devhub::devcard {
    use std::option::{Self, Option};
    use std::string::{Self, String};

    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    const NOT_THE_OWNER: u64 = 0;
    const INSUFFICIENT_FUNDS: u64 = 1;
    const MIN_CARD_COST: u64 = 1;

    // This structure has the necessary information for a developer to has it in his card
    // Different fields show the ability of the developer
    // This is a Sui object since we have key and id.
    struct DevCard has key, store {
        id: UID,
        name: String,
        address: address,
        title: String,
        img_url: Url,
        description: Option<String>,
        years_of_exp: u8,
        technologies: String,
        portfolio: String,
        contact: String,
        open_to_work: bool,
    }

    // This object has the owner of the contract.
    // We are going to send the tokens to this address of the user.
    struct DevHub has key {
        id: UID,
        owner: address,
    }

    // This objct will be send to the contract owner
    // Only the owner can delete object. 
    // To have this system, we are going to require that the transaction sender has the HubOwner object.
    struct HubOwner has key {
        id: UID
    }

    // We are initating our contract.
    // HubOwner object is created and sent to the sender of this transaction
    // DevHub created an freezed as an immutable object. Anyone can read it but cannot write it
    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            HubOwner {id: object::new(ctx)},
            tx_context::sender(ctx)
        );
        transfer::freeze_object(
            DevHub {
                id: object::new(ctx),
                owner: tx_context::sender(ctx),
            }
        );
    }

    // This function creates new card
    // To create the card, required amount should be paid
    // We have the reference for a DevHub object so that the token that is paid to this function can be transferred to the owner using the owner field in the DevHub object
    public entry fun create_card(
        name: vector<u8>,
        title: vector<u8>,
        img_url: vector<u8>,
        years_of_exp: u8,
        technologies: vector<u8>,
        portfolio: vector<u8>,
        contact: vector<u8>,
        payment: Coin<SUI>,
        devhub: &DevHub,
        ctx: &mut TxContext
    ) {
        // In this part, we get the value that came with the transaction. 
        // After we have the value, we transfer the tokens to the owner of the contract which we get it from DevHub object 
        let value = coin::value(&payment);
        assert!(value == MIN_CARD_COST, INSUFFICIENT_FUNDS);
        transfer::transfer(payment, devhub.owner);

        // Creating the new DevCard
        let devcard = DevCard {
            id: object::new(ctx),
            name: string::utf8(name),
            address: tx_context::sender(ctx),
            title: string::utf8(title),
            img_url: url::new_unsafe_from_bytes(img_url),
            description: option::none(),
            years_of_exp,
            technologies: string::utf8(technologies),
            portfolio: string::utf8(portfolio),
            contact: string::utf8(contact),
            open_to_work: true,
        };

        // Sending new object to the sender of this transaction
        transfer::transfer(devcard, tx_context::sender(ctx));
    }

    // With this function the user can change his/her card's description
    // First we check if the address that is sending the transaction is the owner of the card object
    // Then we update the field
    // Since description is an optional field we use swap_or_fill which returns the last value
    // We get the value and delete it using, _= old_description
    public entry fun change_description(card: &mut DevCard, new_description: vector<u8>, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == card.address, NOT_THE_OWNER);
        let old_description = option::swap_or_fill(&mut card.description, string::utf8(new_description));
        _= old_description;
    }

    // With this function, users can change their work status. 
    // First we check if the the transaction sender is the owner of the object
    // Then we update the status
    // Here we did not use swap_or_fill since the data is not optional
    public entry fun change_work_status(card: &mut DevCard, status: bool, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == card.address, NOT_THE_OWNER);
        card.open_to_work = status;
    }

    // With this function the owner of this contract can delete a card
    // For this function the caller should have the HubOwner object
    public entry fun delete_card(_: &HubOwner, devcard: DevCard) {
        let DevCard {
            id, 
            name: _,
            address: _,
            title: _,
            img_url: _,
            description: _,
            years_of_exp: _,
            technologies: _,
            portfolio: _,
            contact: _,
            open_to_work: _,
        } = devcard;

        object::delete(id);
    }

}
