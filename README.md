# Parakeet

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix


### Game Rules
# Parakeet

Parakeet is a card game based on egyptian rats crew.

It is played with a standard 52 card deck.

## Rules
The rules are as follows.

To start, the deck is split evenly between all players. The game is over when one player has all the cards. You want to get all the cards to win.

Players place cards from the top of their deck in the pile in round robin order.

### Slaps
If the order of the cards meets a certain criteria, the pile is eligible for to be taken with a slap. The first player to slap gets the pile.

The slap criteria are:
- Three cards in numeric order
- A Queen card followed by a King card
- Two cards adding up to ten (numbered cards only)
- A "sandwich", when two cards of identical type are separated by one card
- Two identical cards in order

When a player identifies and slaps the pile, it is added to the bottom of their deck.

If the player misidentifies it and slaps, they must place two cards from the top of their deck at the bottom of the pile.

### Challenges

If a player puts down a face card in the pile, then the next player must place cards continuously in the pile until they also put a face card down. If they put a face card down, then that player starts a challenge, and the loop continues until a player fails to put down a face card

If they do not place a face card within the challenge, the pile goes to the player who has most recently placed a face card. If a player wins a challenge, their turn is next

If a player runs out of cards during a challenge, the challenge should pass to the next valid player.

The challenge criteria are:
- Jack: 1 chance to beat
- Queen: 2 chance to beat
- King: 3 chance to beat
- Ace: 4 chance to beat

A slap can be performed at any time during this process
