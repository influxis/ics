from random import *

#####################################################
#
# a Card has a suite and value, and belongs to a Deck
#
class Card:
  suits = ["H", "D", "C", "S"]
  values = ["2","3","4","5","6","7","8","9","T","J","Q","K","A"]

  def __init__(self, value, suit, deck):
    self.value, self.suit, self.deck = value, suit, deck

  def __str__(self):
    return "%s%s" % (self.values[self.value], self.suits[self.suit])

  def val(self):
    v = self.values[self.value]
    if v == "K":
        return 10
    elif v == "Q":
        return 10
    elif v == "J":
        return 10
    elif v == "T":
        return 10
    elif v == "A":
        return 11
    else:
        return int(v)

#####################################################
#
# This class actually contains multiple decks
#
class Deck:
  def __init__(self, ndecks=1):
    self.ndecks = ndecks
    self.reshuffle()

  def reshuffle(self):
    print "shuffling..."
    self.cards = []

    for d in range(self.ndecks):
      for x in range(13):
        for y in range(4):
          self.cards.append(Card(x, y, d))
  
    shuffle(self.cards)

  def __str__(self):
    return str(self.cards)

  def length(self):
    return len(self.cards)

  def deal(self):
    if len(self.cards) == 0:
      self.reshuffle()

    return self.cards.pop()

  def deal_for(self, player):
    player.deal(self)

#####################################################
#
# This class implements common (player/dealer) logic
#
class Common:
  def __init__(self, name):
    self.name =  name
    self.newround()

  def __str__(self):
    return "{total:%d, aces:%d, hand:%s}" % (self.total, self.aces, self.hand)

  def newround(self):
    self.hand = []
    self.total = 0
    self.aces = 0

  def deal(self, deck):
    card = deck.deal()
    self.hand.append(card)
    v = card.val()
    if v==11: self.aces += 1
    self.total += v
    while self.total > 21 and self.aces > 0:
      self.total -= 10
      self.aces -= 1
    return self.total

  def tie(self):
    pass

  def isblackjack(self):
    return self.total==21 and len(self.hand)==2

  def win(self):
    print "%s win!" % self.name
    if self.isblackjack():
      print "Blackjack!"
      return True
    else:
      return False

  def busted(self):
    self.total = 0
    print "%s busted!" % self.name

  def toVO(self, firstonly=False):
    hand = []
    if firstonly:
      total = -1
      bj = False
    else:
      total = self.total
      bj = self.isblackjack()

    for i,c in enumerate(self.hand):
      if i==0 or not firstonly:
        hand.append(str(c))
      else:
        hand.append('##')

    vo = {
      'hand'  : hand,
      'total' : total,
      'bj'    : bj
    }

    return vo
  
#####################################################
#
# This class stores the dealer state
#
class Dealer(Common):
  def __init__(self, name="Dealer"):
    Common.__init__(self, name)

#####################################################
#
# This class stores a player state
#
class Player(Common):
  def __init__(self, name="Player", chips=100):
    Common.__init__(self, name)
    self.chips = chips;
    self.currentbet = 0

  def bet(self, b):
    if b > self.chips:
      return False

    self.chips -= b
    self.currentbet = b
    print "%s's has %d chips. Current bet is %d" % (self.name, self.chips, self.currentbet)

  def tie(self):
    Common.tie(self)
    self.chips += self.currentbet

  def win(self):
    bj = Common.win(self)
    self.chips += 2*self.currentbet

    # BlackJack pays 3:2
    if bj:
      self.chips += self.currentbet

  def toVO(self, firstonly=False):
    vo = Common.toVO(self, firstonly)
    vo['chips'] = self.chips
    vo['bet'] = self.currentbet
    return vo

#####################################################
#
# Main application
#
if __name__ == "__main__":
  deck = Deck(1)
  dealer = Dealer()
  player = Player()

  def printcards(player, firstonly=False):
    print "%s's cards:" % player.name
    vo = player.toVO(firstonly)
    hand = vo['hand']
    total = vo['total']
    for c in hand:
      print "  %s" % c,
    if total <= 0:
      print "\n"
    else:
      print " (%d)\n" % total

  while True:
    print ""
    print "New round! %d cards left" % deck.length()
    dealer.newround()
    player.newround()

    #
    # accept bets
    #
    player.bet(5)

    #
    # deal two cards
    # 1)
    player.deal(deck)
    dealer.deal(deck)
    # 2)
    player.deal(deck)
    dealer.deal(deck)

    printcards(dealer, True)
    printcards(player)

    p = player.total
    while True:
      if p > 21:
        player.busted()
        break
      elif p == 21:
        break
         
      hs = raw_input("Hit or Stand/Done (h or s): ").lower()
      if 'h' in hs:
        p = player.deal(deck)
        printcards(player)
      else:
        break

    printcards(dealer)
    if p > 21:
      dealer.win()
      continue

    d = dealer.total
    while d < 17:
      d = dealer.deal(deck)
      printcards(dealer)

    if d > 21:
      dealer.busted()
      player.win()
    elif d > p:
      dealer.win()
    elif d == p:
      if dealer.isblackjack() and player.isblackjack():
        print "Tie!"
        player.tie()
      else:
        dealer.win()  
    else:
      player.win()
