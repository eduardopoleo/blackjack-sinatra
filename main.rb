require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
:path => '/',
:secret => 'your_secret'
# I can use this helpers methods even in the views
# Instance variables e.g @error are statless as opposed to the session
# This is what allows him to display the message he wants because they
# reset everytime 
# before do filters help you organize you workflow
# using wells to surround cards
# we can build a card image function that outputs the string already including
# the img tag and then just use it on the erb because you can use helpers there
# using halt stops the execution of the action and also allows you to perform an alternative action
helpers do

  def cards_with_proper_name(hand,cover_needed)
    new_hand = []

    if cover_needed
      new_hand.push("images/cards/cover.jpg", "images/cards/" + hand[1][0] + "_" + hand[1][1] + ".jpg" )
    else
      hand.each do |card|
        new_hand.push("images/cards/" + card[0] + "_" + card[1] + ".jpg")
      end
    end
    new_hand
  end

  def calculate_score(hand)
    total_value = 0
    ace_counter = 0
   
    hand.each do |card|
      if card[1] == 'jack' || card[1] == 'queen' || card[1] == 'king'
        total_value += 10
      elsif card[1] != 'ace'
        total_value += card[1].to_i
      else
        ace_counter += 1
      end
    end
    # Aces value are estimated after adding the other cards with fixed value. 
    # Aces value are set to 1 or 11 depending on what's more convinient for the player. 
    while ace_counter > 0
      if total_value + 11 <= 21 
        total_value += 11
      else
        total_value += 1
      end
      ace_counter -= 1 
    end
    total_value
  end
end

get '/' do
  session[:money] = 500
  session[:bet] = 0
  erb :get_name
end

post '/get_name' do
  session[:name] = params[:name]
  if session[:name].length < 2
    @error = "Please enter a longer name!"
    halt erb :get_name
  end
  redirect '/bet'
end

get '/bet' do
  if session[:money] == 0
    erb :broke
  else
    erb :get_bet
  end
end

post '/get_bet' do
  session[:bet] = params[:bet].to_i

  if session[:bet] > session[:money]
    @error = "Aghr, you do not have that kind of money pal!"
    erb :get_bet
  elsif session[:bet] < 0
    @error = "We do not accept negative bets in here."
    erb :get_bet
  elsif session[:bet] == 0
    @error = " You need to bet to play!"
    erb :get_bet
  else
    redirect '/game'
  end
end

get '/game' do
  #variables and important constants
  SUIT = ['clubs', 'diamonds', 'hearts', 'spades']
  NUMBER = ['2','3','4','5','6','7','8','9','10','jack','queen','king', 'ace']

  session[:deck] = SUIT.product(NUMBER).shuffle
  session[:name]
  session[:money]
  session[:bet]
  session[:player_hand] = []
  session[:dealer_hand] = []
  session[:round_over?] = false
  session[:dealer_plays?] = false

  2.times{session[:player_hand] << session[:deck].pop}
  2.times{session[:dealer_hand] << session[:deck].pop}


  session[:player_score] = calculate_score(session[:player_hand])
  session[:dealer_score] = calculate_score(session[:dealer_hand])

  session[:player_hand_to_display] = cards_with_proper_name(session[:player_hand], false)
  session[:dealer_hand_to_display] = cards_with_proper_name(session[:dealer_hand], true)
  
  if session[:player_score] == 21
    session[:round_over?] = true
    session[:player_won?] = true
    session[:money] += session[:bet]*1.5.floor
    @success = "You hit blackjack! Your money available is #{session[:money]}."
  end

  erb :game
end

# There is no need for a while loop because we have routes 
post "/player_hits" do
  session[:player_hand] << session[:deck].pop
  session[:player_hand_to_display] = cards_with_proper_name(session[:player_hand], false)
  session[:player_score] = calculate_score(session[:player_hand])
  
  if session[:player_score] > 21
    session[:round_over?] = true
    session[:money] -= session[:bet]
    @error = "You busted with #{session[:player_score]}! Your money available is $#{session[:money]}." 
  end

  if session[:player_score] == 21
    redirect '/show_dealer_cards'
  end

  erb :game, layout: false
end

post "/show_dealer_cards" do
  session[:dealer_plays?] = true
  session[:dealer_hand_to_display] = cards_with_proper_name(session[:dealer_hand], false)
  
  if session[:dealer_score] >= 17
    if session[:dealer_score] >= session[:player_score]
      session[:money] -= session[:bet]
      @error = "The dealer stayed with #{session[:dealer_score]} and you with #{session[:player_score]}. You lost. Your current balance is $#{session[:money]}."
    else
      session[:money] += session[:bet]
      @success = "You beat the dealer! You stayed at #{session[:player_score]} and she stayed at #{session[:dealer_score]}. Your balance is $#{session[:money]}."
    end
  end
  erb :game, layout: false
end

post "/dealer_plays" do 
  session[:dealer_plays?] = true
  session[:dealer_hand] << session[:deck].pop
  session[:dealer_hand_to_display] = cards_with_proper_name(session[:dealer_hand], false)
  
  session[:dealer_score] = calculate_score(session[:dealer_hand])
  if session[:dealer_score] > 21
    session[:money] += session[:bet]
    @success = "The dealer busted with #{session[:dealer_score]}! You won. Your balance is $#{session[:money]}."
  elsif session[:dealer_score] >= session[:player_score]
    session[:money] -= session[:bet]
    @error = "The dealer stayed with #{session[:dealer_score]} and you with #{session[:player_score]}. You lost. Your current balance is $#{session[:money]}."
  elsif session[:dealer_score] >= 17 && session[:dealer_score] < session[:player_score]
    session[:money] += session[:bet]
    @success = "You beat the dealer! You stayed at #{session[:player_score]} and she stayed at #{session[:dealer_score]}. Your balance is $#{session[:money]}."
  end

  erb :game, layout: false
end

get "/game_finished" do
  erb :finish
end

# deal_cards to player 
# Deal_card to dealer but only show one
# ask the player if he wants another card
# Dealer shows cards and plays
# compare results
# if player still has money ask him if he wants to play another bet
# when the player runs out of money initilize the game again

 
