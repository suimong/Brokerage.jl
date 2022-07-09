using Test, Brokerage

# to init with a new database -> "../test/newdbname.sqlite" 
const DBFILE = joinpath(dirname(pathof(Brokerage)), "../test/portfolios.sqlite")
const AUTHFILE = "file://" * joinpath(dirname(pathof(Brokerage)), "../resources/authkeys.json")

server = @async Brokerage.run(DBFILE, AUTHFILE)

## do the following in a seperate client terminal

# Client.createUser("aaron", "password123")
# user = Client.loginUser("aaron", "password123")

# por1 = Client.createPortfolio("Trader 1", 10500.0, [1, 2])

## Order testing
# ord1 = Client.placeLimitOrder(1,1287,"SELL_ORDER",99.0,7,por1.id)
# ord2 = Client.placeLimitOrder(1,1283,"BUY_ORDER",100.0,7,por1.id)
# # OMS.ob1 # changed order book can only be seen on server side terminal ** (haven't incorporated qoute service yet)

# ord3 = Client.placeMarketOrder(1,1211,"SELL_ORDER",7,por1.id)
# ord4 = Client.placeMarketOrder(1,1281,"BUY_ORDER",7,por1.id)

# ord5 = Client.placeMarketOrder(1,1211,"BUY_ORDER",5.0,por1.id,byfunds = true)
# ord6 = Client.placeMarketOrder(1,1281,"BUY_ORDER",100.0,por1.id,byfunds = true)

# ord7 = Client.placeLimitOrder(1,1280,"BUY_ORDER",98.0,3,por1.id)
# Client.placeCancelOrder(1,1280,"BUY_ORDER",98.0,por1.id)

## Quote testing
# spread = Client.getBidAsk(1)
# depth = Client.getBookDepth(1)
# spread_volume = Client.getBidAskVolume(1)
# n_orders_spread = Client.getBidAskOrders(1)

# @testset "Test 1" begin
#     @test Client.pickRandomPortfolio() == por1
#     @test Client.pickRandomPortfolio() == por1
#     @test Client.getPortfolio(por1.id) == por1
# end

# push!(por1.holdings, 3)
# por2 = Client.updatePortfolio(por1)

# @testset "Test 2" begin
#     @test length(por2.holdings) == 3
#     @test length(Client.getPortfolio(por1.id).holdings) == 3
# end

# Client.deletePortfolio(por1.id)
# por2 = Client.createPortfolio("Trader 2", 9670.0, [2, 4])
# @test Client.pickRandomPortfolio() == por2

# Client.createUser("aaronW", "password456")
# user = Client.loginUser("aaronW", "password456")

# newuser_por1 = Client.createPortfolio("Trader 3", 10500.80, [1, 2, 3, 4])

# For trouble-shooting VL_LimitOrderBook integration...
# using VL_LimitOrderBook
# order = Model.LimitOrder(1,101, "SELL_ORDER", 99.10, 5, 1287)
# Service.processTrade(order)
# order = Model.LimitOrder(1,101, "BUY_ORDER", 99.10, 5, 1287)
# Service.processTrade(order)
# VL_LimitOrderBook notify functionality needs to be revisted, the above order does not appear to match and notify