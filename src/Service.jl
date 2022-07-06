module Service
# perform the services defined in the Resource layer and validate inputs

using Dates, ExpiringCaches
using ..Model, ..Mapper, ..Auth, ..OMS
# using ..Model, ..NormalizedMapper, ..Auth

# ======================================================================================== #
#----- Account Services -----#

function createPortfolio(obj)
    @assert haskey(obj, :name) && !isempty(obj.name)
    @assert haskey(obj, :holdings) && !isempty(obj.holdings)
    @assert haskey(obj, :cash) && 1.0 < obj.cash < 1000000.0
    portfolio = Portfolio(obj.name, obj.cash, obj.holdings)
    Mapper.create!(portfolio)
    # NormalizedMapper.create!(portfolio)
    return portfolio
end

@cacheable Dates.Hour(1) function getPortfolio(id::Int64)::Portfolio
    Mapper.get(id)
    # NormalizedMapper.get(id)
end

# consistent with model struct, not letting client define their own id, we manage these as a service
function updatePortfolio(id, updated)
    portfolio = Mapper.get(id)
    # portfolio = NormalizedMapper.get(id)
    portfolio.name = updated.name
    portfolio.cash = updated.cash
    portfolio.holdings = updated.holdings
    Mapper.update(portfolio)
    # NormalizedMapper.update(portfolio)
    delete!(ExpiringCaches.getcache(getPortfolio), (id,))
    return portfolio
end

function deletePortfolio(id)
    Mapper.delete(id)
    # NormalizedMapper.delete(id)
    delete!(ExpiringCaches.getcache(getPortfolio), (id,))
    return
end

function pickRandomPortfolio()
    portfolios = Mapper.getAllPortfolios()
    # portfolios = NormalizedMapper.getAllPortfolios()
    leastTimesPicked = minimum(x->x.timespicked, portfolios)
    leastPickedPortfolio = filter(x->x.timespicked == leastTimesPicked, portfolios)
    pickedPortfolio = rand(leastPickedPortfolio)
    pickedPortfolio.timespicked += 1
    Mapper.update(pickedPortfolio)
    # NormalizedMapper.update(pickedPortfolio)
    delete!(ExpiringCaches.getcache(getPortfolio), (pickedPortfolio.id,))
    @info "picked portfolio = $(pickedPortfolio.name) on thread = $(Threads.threadid())"
    return pickedPortfolio
end

# creates User struct defined in Model.jl
function createUser(user)
    @assert haskey(user, :username) && !isempty(user.username)
    @assert haskey(user, :password) && !isempty(user.password)
    user = User(user.username, user.password)
    Mapper.create!(user)
    # NormalizedMapper.create!(user)
    return user
end

# done this way so that we can persist user
function loginUser(user)
    persistedUser = Mapper.get(user)
    # persistedUser = NormalizedMapper.get(user)
    if persistedUser.password == user.password
        persistedUser.password = ""
        return persistedUser
    else
        println("persistedUser Login Error: User not recognized")
        throw(Auth.Unauthenticated())
    end
end

# ======================================================================================== #
#----- Order Services -----#

function placeLimitOrder(id, obj) # make this @cacheable ? delete when matched or at EOD?
    @assert haskey(obj, :ticker) && !isempty(obj.ticker) # TODO: Check if ticker exists in OMS
    @assert haskey(obj, :order_id) && !isempty(obj.order_id) # TODO: make this service-managed
    @assert haskey(obj, :order_side) && !isempty(obj.order_side) # TODO: Check if either "BUY_ORDER" or "SELL_ORDER"
    @assert haskey(obj, :limit_price) && !isempty(obj.limit_price)
    @assert haskey(obj, :limit_size) && !isempty(obj.limit_size)
    # TODO:
    # if BUY_ORDER
    # check OMS layer to see how many funds are needed
    # from Mapper layer, check if sufficient funds available
    # return either rejection or acknowledgement @info message
    # break if rejection

    # if SELL_ORDER
    # from Mapper layer, check if sufficient shares available
    # return either rejection or acknowledgement @info message
    # break if rejection

    # TODO:
    # from Mapper layer, create and return unique transaction_id
    # order_id = transaction_id
    # TODO: Set-up fill_mode functionality
    order = LimitOrder(obj.ticker, obj.order_id, obj.order_side, obj.limit_price, obj.limit_size)

    # TODO: do the following @asynch
    # send order to OMS layer for fulfillment
    processTrade(id, order)

    # define variable for processTrade and if = true then delete @cachable order? Or do that in processTrade instead?

    return order  
end

# submit_market_order!(ob::OrderBook,side::OrderSide,mo_size[,fill_mode::OrderTraits])
# submit_market_order_byfunds!(ob::OrderBook,side::Symbol,funds[,mode::OrderTraits])

# function cancelOrder(id, order_id)
#     acct_id = id
#     # cancel_order!(ob,orderid,side,price)
# end

# ======================================================================================== #
#----- Quote Services -----#

# function getBidAsk()
#     # best_bid_ask(ob) 
# end

# best_bid_ask(ob) # returns tuple of best bid and ask prices in the order book
# book_depth_info(ob) # nested dict of prices, volumes and order counts at a specified max_depth (default = 5)
# get_acct(ob,acct_id) # return all open orders assigned to account `acct_id`
# volume_bid_ask(ob)
# n_orders_bid_ask(ob)

# ======================================================================================== #
#----- Trade Services -----#

function processTrade(id, order::LimitOrder)
    # navigate order to correct location
    if order.order_side == "SELL_ORDER"
        trade = OMS.processLimitOrderSale(id, order)
        @info "Trade fulfilled at $(Dates.now(Dates.UTC)). Your order is complete and your account has been updated."
        # TODO: incorporate complete trade functionality below
        # if trade[1] == nothing
        #     @info "Trade fulfilled at $(Dates.now(Dates.UTC)). Your order is complete and your account has been updated."
        #     # TODO: update portfolio accordingly           
        # end
    elseif order.order_side == "BUY_ORDER"
        trade = OMS.processLimitOrderPurchase(id, order)
        @info "Trade fulfilled at $(Dates.now(Dates.UTC)). Your order is complete and your account has been updated."
        # TODO: incorporate complete trade functionality below
        # if trade[1] == nothing
        #     @info "Trade fulfilled at $(Dates.now(Dates.UTC)). Your order is complete and your account has been updated."
        #     # TODO: update portfolio accordingly           
        # end
    end
    # return true ?
end

# TODO: Other info messages (examples below)

# "Update (timestamp): Your order to sell 100 shares of NOK has been filled at an average price of $4.01 per share. Your order is complete."

# "We've received your order to open 1 MVIS Call Credit Spread at a minimum of $0.40 per unit. If this order isn't filled by the end of market hours today (4pm ET), it'll be canceled."
# "Your order to open 1 MVIS Call Credit Spread wasn't filled today, and has been automatically canceled."

# "Your order to sell to close 1 contract of T $29.50 Call 4/1 has been filled for an average price of $94.00 per contract. Your order is complete."

# "Update: Because you owned 0.526674 shares of NVDA on 6/8, you've received a dividend payment of $0.02."

end # module