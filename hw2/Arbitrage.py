import itertools


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


def exchange_token(x: int, y: int, delta_x: float) -> float:
    return float((997 * delta_x * y) / (1000 * x + 997 * delta_x))


def get_token_list(token_dict: dict) -> list:
    token = set()
    for key, value in token_dict.items():
        token.update(key)
    return list(sorted(token))


def get_token_permutations(token_list: list) -> list:
    perms = list()
    for i in range(3, len(token_list) + 1):
        els = [
            list(x) for x in itertools.permutations(token_list, i)
            if x[0] == 'tokenB'
        ]  # only extract tokenB
        perms.extend(els)
    return perms


if __name__ == "__main__":
    liquidity = {
        ("tokenA", "tokenB"): (17, 10),
        ("tokenA", "tokenC"): (11, 7),
        ("tokenA", "tokenD"): (15, 9),
        ("tokenA", "tokenE"): (21, 5),
        ("tokenB", "tokenC"): (36, 4),
        ("tokenB", "tokenD"): (13, 6),
        ("tokenB", "tokenE"): (25, 3),
        ("tokenC", "tokenD"): (30, 12),
        ("tokenC", "tokenE"): (10, 8),
        ("tokenD", "tokenE"): (60, 25),
    }

    token_list = get_token_list(liquidity)
    token_perms = get_token_permutations(token_list)
    arbitrage_table = calculate_arbitrage(liquidity, token_perms)

    # print path
    for value, arbitrage in arbitrage_table:
        print(*arbitrage, sep="->", end="")
        print(f'->{arbitrage[0]}, {arbitrage[0]} ', end="")
        print(f'balance={value}')
