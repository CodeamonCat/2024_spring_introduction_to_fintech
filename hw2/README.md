# 2024-Spring-HW2

Please complete the report problem below:

## Problem 1

Provide your profitable path, the amountIn, amountOut value for each swap, and your final reward (your tokenB balance).

> Solution \
> The profitable path: `tokenB->tokenA->tokenD->tokenC->tokenB, tokenB balance=20.129888944077443`

- Before Arbitrage tokenB Balance: 5000000000000000000
- tokenB->tokenA
  - amountIn: 5000000000000000000 [5e18] tokenB
  - amountOut: 5655321988655321988 [5.655e18] tokenA
- tokenA->tokenD
  - amountIn: 5655321988655321988 [5.655e18] tokenA
  - amountOut: 2458781317097933552 [2.458e18] tokenD
- tokenD->tokenC
  - amountIn: 2458781317097933552 [2.458e18] tokenD
  - amountOut: 5088927293301515695 [5.088e18] tokenC
- tokenC->tokenB
  - amountIn: 5088927293301515695 [5.088e18] tokenC
  - amountOut: 20129888944077446732 [2.012e19] tokenB
- After Arbitrage tokenB Balance: 20129888944077446732

## Problem 2

What is slippage in AMM, and how does Uniswap V2 address this issue? Please illustrate with a function as an example.

> Solution \
> Since the change in token price is caused by the total movement of the entire current market, the Slippage in AMM refers to the difference between the expected price of a trade and the price at which the trade is executed. The final execution price vs. the intended execution price can be categorized as positive slippage, no slippage, or negative slippage.

$$
\begin{align*}
    \text{Uniswap v2}&
    \begin{cases}
        x\cdot y=k \\
        (x+dx)\cdot(y-dy)=k \\
    \end{cases} \\
    \text{Exchange volumn}&\Rightarrow dy=\frac{y\cdot dx}{x+dx} \\
    \text{Price ratio of exchange}&\Rightarrow\frac{dx}{dy}=\frac{x+dx}{y} \\
    \text{slippage price}&=\underbrace{\frac{dx}{dy}}_{\text{Price ratio of exchange}}-\underbrace{\frac{x}{y}}_{\text{Price ratio before exchange}}=\frac{dx}{y}
\end{align*}
$$

> From the equation above, we know that the greater the transaction volume, the greater the slippage and the greater the deviation from the actual price. Besides, from the Uniswap V2 code below, we know that

$$
\text{PriceImpact}\Rightarrow\frac{\text{midPrice}\times\text{inputAmount}-\text{outputAmount}}{\text{midPrice}\times\text{inputAmount}}
$$

```typescript=
// reference: https://github.com/Uniswap/sdk-core/blob/main/src/utils/computePriceImpact.ts
import { Currency, CurrencyAmount, Percent, Price } from '../entities'

/**
 * Returns the percent difference between the mid price and the execution price, i.e. price impact.
 * @param midPrice mid price before the trade
 * @param inputAmount the input amount of the trade
 * @param outputAmount the output amount of the trade
 */
export function computePriceImpact<TBase extends Currency, TQuote extends Currency>(
  midPrice: Price<TBase, TQuote>,
  inputAmount: CurrencyAmount<TBase>,
  outputAmount: CurrencyAmount<TQuote>
): Percent {
  const quotedOutputAmount = midPrice.quote(inputAmount)
  // calculate price impact := (exactQuote - outputAmount) / exactQuote
  const priceImpact = quotedOutputAmount.subtract(outputAmount).divide(quotedOutputAmount)
  return new Percent(priceImpact.numerator, priceImpact.denominator)
}
```

## Problem 3

Please examine the mint function in the UniswapV2Pair contract. Upon initial liquidity minting, a minimum liquidity is subtracted. What is the rationale behind this design?

> Solution \
> From the [Uniswap v2 Core whitepaper](https://uniswap.org/whitepaper.pdf), the section 3.4 Initialization of liquidity token supply in the whitepaper, the reasoning behind subtracting minimum liquidity during the initial minting of liquidity tokens is elucidated. \
> Uniswqp v2 initially mints shares equal to the geometric mean of the amounts deposited

$$
S_\text{minted}=\sqrt{x_\text{deposited}\times y_\text{deposited}}
$$

> The formula above ensures that the value of a liquidity pool share at any time is essentially independent of the ratio at which liquidity was initially deposited, and also ensures that a liquidity pool share will never be worth less than the geometric mean of the reserves in that pool. It is possible for the value of a liquidity pool share to grow over time, either by accumulating trading fees or through `donations` to the liquidity pool. In theory, this could result in a situation where the value of the minimum quantity of liquidity pool shares (1e-18 pool shares) is worth so much that it becomes infeasible for small liquidity providers to provide any liquidity. \
> To mitigate this, Uniswap v2 burns the first `1e-15 (0.000000000000001)` pool shares that are minted (1000 times the minimum quantity of pool shares), sending them to the zero address instead of to the minter. This should be a negligible cost for almost any token pair.11 But it dramatically increases the cost of the above attack. In order to raise the value of a liquidity pool share to `$100`, the attacker would need to donate `$100,000` to the pool, which would be permanently locked up as liquidity. \
> As a result, the rationale behind the design is to increase the cost of the attack.

```solidity=
// reference: https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol

uint public constant MINIMUM_LIQUIDITY = 10**3;

// this low-level function should be called from a contract which performs important safety checks
function mint(address to) external lock returns (uint liquidity) {
    (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
    uint balance0 = IERC20(token0).balanceOf(address(this));
    uint balance1 = IERC20(token1).balanceOf(address(this));
    uint amount0 = balance0.sub(_reserve0);
    uint amount1 = balance1.sub(_reserve1);

    bool feeOn = _mintFee(_reserve0, _reserve1);
    uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
    if (_totalSupply == 0) {
        liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
        _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
    } else {
        liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
    }
    require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
    _mint(to, liquidity);

    _update(balance0, balance1, _reserve0, _reserve1);
    if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
    emit Mint(msg.sender, amount0, amount1);
}
```

## Problem 4

Investigate the minting function in the UniswapV2Pair contract. When depositing tokens (not for the first time), liquidity can only be obtained using a specific formula. What is the intention behind this?

> Solution \
> From the [Uniswap v2 Core whitepaper](https://uniswap.org/whitepaper.pdf), we know that once a new liquidity provider deposits tokens into an existing Uniswap pair, the number of liquidity tokens minted is computed based on the existing quantity of tokens:

$$
S_\text{minted}=\frac{x_\text{deposited}}{x_\text{starting}}\cdot S_\text{starting}
$$

> Besides, from the code below, it shows that

```solidity=
liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
```

> The liquidity that is credited to the user, and later minted to the users, is the lesser of two values, which is scaled by the totalSupply of LP tokens. The fact that the user will get the worse of the two ratios (amount0 / \_reserve0 or amount1 / \_reserve1) they provide incentivizes them to increase the supply of token0 and token1 without changing the ratio of token0 and token1, this can prevent the attacker to steal liquidity from other LP providers since adding liquidity should not affect price.

```solidity=
// reference: https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol

uint public constant MINIMUM_LIQUIDITY = 10**3;

// this low-level function should be called from a contract which performs important safety checks
function mint(address to) external lock returns (uint liquidity) {
    (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
    uint balance0 = IERC20(token0).balanceOf(address(this));
    uint balance1 = IERC20(token1).balanceOf(address(this));
    uint amount0 = balance0.sub(_reserve0);
    uint amount1 = balance1.sub(_reserve1);

    bool feeOn = _mintFee(_reserve0, _reserve1);
    uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
    if (_totalSupply == 0) {
        liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
        _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
    } else {
        liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
    }
    require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
    _mint(to, liquidity);

    _update(balance0, balance1, _reserve0, _reserve1);
    if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
    emit Mint(msg.sender, amount0, amount1);
}
```

## Problem 5

What is a sandwich attack, and how might it impact you when initiating a swap?

> Solution \
> Sandwich attacks are a common type of attack on decentralized exchange users. During sandwiching, attackers will wrap user's swap transactions in their two transactions: one goes before the user transaction and the other goes after it. In the first transaction, an attacker modifies the state of a pool so that the swap becomes very unprofitable for the user and somewhat profitable for the attacker. This is achieved by adjusting pool liquidity so that user trade happens at a lower price. In the second transaction, the attacker reestablishes pool liquidity and the price. As a result, the user get much fewer tokens than expected due to manipulated prices, and the attacker gets some profit.

## Bonus

Please provide the most profitable path among all possible swap paths and the corresponding Python script, along with its profit. Only the accurate answer will be accepted.

> Solution \
> Among all profitable paths, only two profitable paths can acquire more than 20 tokens, and both of the profitable paths start with 5 tokenB. As a result, the most profitable is the same as the profitable path that I provided in Problem 1. Besides, the other profitable paths that start from all possible tokens are listed below. To check all other profitable paths that start from all possible tokens, we can modify the code below by removing the if statement within asking the get_token_permutations function and adjusting the threshold from 20 to the initial value of 5 tokens.

- tokenB->tokenA->tokenD->tokenC->tokenB, tokenB balance=20.129888944077443
- tokenB->tokenA->tokenE->tokenD->tokenC->tokenB, tokenB balance=20.042339589188174
- tokenB->tokenD->tokenC->tokenB, tokenB balance=17.129647787090473
- tokenB->tokenE->tokenD->tokenC->tokenB, tokenB balance=14.34639465845742
- tokenB->tokenA->tokenC->tokenB, tokenB balance=13.376356555351348
- tokenB->tokenE->tokenA->tokenD->tokenC->tokenB, tokenB balance=13.190994343980773
- tokenB->tokenA->tokenD->tokenC->tokenE->tokenB, tokenB balance=11.806577688562932
- tokenA->tokenD->tokenC->tokenB->tokenA, tokenA balance=11.216361176726753
- tokenA->tokenE->tokenD->tokenC->tokenB->tokenA, tokenA balance=11.193465536305583
- tokenB->tokenD->tokenC->tokenE->tokenB, tokenB balance=10.36482443041647
- tokenC->tokenE->tokenD->tokenC, tokenC balance=9.706581095698438
- tokenA->tokenC->tokenB->tokenA, tokenA balance=9.493660532957799
- tokenA->tokenD->tokenC->tokenE->tokenB->tokenA, tokenA balance=9.076055986228834
- tokenB->tokenD->tokenE->tokenA->tokenC->tokenB, tokenB balance=8.73664221254987
- tokenB->tokenA->tokenC->tokenE->tokenB, tokenB balance=8.427416719282709
- tokenB->tokenD->tokenA->tokenC->tokenB, tokenB balance=8.405266301892134
- tokenB->tokenA->tokenE->tokenC->tokenB, tokenB balance=8.102448897437187
- tokenD->tokenC->tokenE->tokenD, tokenD balance=7.787167581092197
- tokenB->tokenA->tokenD->tokenE->tokenC->tokenB, tokenB balance=7.689424678064365
- tokenA->tokenC->tokenE->tokenB->tokenA, tokenA balance=7.57082509843417
- tokenC->tokenB->tokenA->tokenE->tokenD->tokenC, tokenC balance=7.354638402024025
- tokenB->tokenE->tokenA->tokenC->tokenB, tokenB balance=7.343725908386695
- tokenA->tokenE->tokenC->tokenB->tokenA, tokenA balance=7.310330969595884
- tokenC->tokenB->tokenA->tokenD->tokenC, tokenC balance=7.289937169128189
- tokenA->tokenD->tokenE->tokenC->tokenB->tokenA, tokenA balance=7.1187810336372985
- tokenA->tokenD->tokenC->tokenE->tokenA, tokenA balance=7.094184134525014
- tokenC->tokenB->tokenD->tokenC, tokenC balance=6.951520960036133
- tokenB->tokenE->tokenD->tokenA->tokenC->tokenB, tokenB balance=6.8610901293046815
- tokenC->tokenE->tokenB->tokenA->tokenD->tokenC, tokenC balance=6.618654604319989
- tokenB->tokenA->tokenE->tokenB, tokenB balance=6.504955884059334
- tokenA->tokenE->tokenB->tokenA, tokenA balance=6.391513700643288
- tokenA->tokenD->tokenE->tokenB->tokenA, tokenA balance=6.195341598832742
- tokenB->tokenA->tokenD->tokenE->tokenB, tokenB balance=6.148110317660673
- tokenC->tokenB->tokenE->tokenD->tokenC, tokenC balance=6.02128957742055
- tokenC->tokenE->tokenA->tokenD->tokenC, tokenC balance=5.881241661736145
- tokenB->tokenD->tokenE->tokenC->tokenB, tokenB balance=5.816018142435081
- tokenC->tokenE->tokenB->tokenD->tokenC, tokenC balance=5.730387518053722
- tokenB->tokenD->tokenA->tokenC->tokenE->tokenB, tokenB balance=5.601325289877443
- tokenA->tokenC->tokenE->tokenD->tokenB->tokenA, tokenA balance=5.302588422258238
- tokenB->tokenD->tokenC->tokenA->tokenE->tokenB, tokenB balance=5.024399258538538

```python=
def calculate_arbitrage(liquidity: dict, token_perms: list) -> list:
    arbitrage = list()
    for tokens in token_perms:
        units = 5.0
        for idx in range(len(tokens) - 1):
            if (tokens[idx] < tokens[idx + 1]):
                units = exchange_token(
                    liquidity[tokens[idx], tokens[idx + 1]][0],
                    liquidity[tokens[idx], tokens[idx + 1]][1], units)
            else:
                units = exchange_token(
                    liquidity[tokens[idx + 1], tokens[idx]][1],
                    liquidity[tokens[idx + 1], tokens[idx]][0], units)
        # exchange back to original token
        if (tokens[-1] < tokens[0]):
            units = exchange_token(liquidity[tokens[-1], tokens[0]][0],
                                   liquidity[tokens[-1], tokens[0]][1], units)
        else:
            units = exchange_token(liquidity[tokens[0], tokens[-1]][1],
                                   liquidity[tokens[0], tokens[-1]][0], units)
        # threshold
        if units > 20:
            arbitrage.append([units, tokens])
    return sorted(arbitrage, reverse=True)

def get_token_permutations(token_list: list) -> list:
    perms = list()
    for i in range(3, len(token_list) + 1):
        els = [
            list(x) for x in itertools.permutations(token_list, i)
            if x[0] == 'tokenB'
        ]  # only extract tokenB
        perms.extend(els)
    return perms
```
