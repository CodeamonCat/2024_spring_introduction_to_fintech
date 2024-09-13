"""
Package Import
"""
import yfinance as yf
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import quantstats as qs
import gurobipy as gp
import argparse
import warnings
"""
Project Setup
"""
warnings.simplefilter(action="ignore", category=FutureWarning)

assets = [
    "SPY",
    "XLB",
    "XLC",
    "XLE",
    "XLF",
    "XLI",
    "XLK",
    "XLP",
    "XLRE",
    "XLU",
    "XLV",
    "XLY",
]

start = "2019-01-01"
end = "2024-04-01"
data = pd.DataFrame()

# Fetch the data for each stock and concatenate it to the `data` DataFrame
for asset in assets:
    raw = yf.download(asset, start=start, end=end)
    raw["Symbol"] = asset
    data = pd.concat([data, raw], axis=0)

# Initialize df and df_returns
df = portfolio_data = data.pivot_table(index="Date",
                                       columns="Symbol",
                                       values="Adj Close")
df_returns = df.pct_change().fillna(0)
"""
Problem 1: 

Implement an equal weighting strategy as dataframe "eqw". Please do "not" include SPY.
"""


class EqualWeightPortfolio:

    def __init__(self, exclude):
        self.exclude = exclude

    def calculate_weights(self):
        # Get the assets by excluding the specified column
        assets = df.columns[df.columns != self.exclude]
        self.portfolio_weights = pd.DataFrame(index=df.index,
                                              columns=df.columns)
        """
        TODO: Complete Task 1 Below
        """
        self.portfolio_weights[assets] = 1 / len(assets)
        """
        TODO: Complete Task 1 Above
        """
        self.portfolio_weights.ffill(inplace=True)
        self.portfolio_weights.fillna(0, inplace=True)

    def calculate_portfolio_returns(self):
        # Ensure weights are calculated
        if not hasattr(self, "portfolio_weights"):
            self.calculate_weights()

        # Calculate the portfolio returns
        self.portfolio_returns = df_returns.copy()
        assets = df.columns[df.columns != self.exclude]
        self.portfolio_returns["Portfolio"] = (
            self.portfolio_returns[assets].mul(
                self.portfolio_weights[assets]).sum(axis=1))

    def get_results(self):
        # Ensure portfolio returns are calculated
        if not hasattr(self, "portfolio_returns"):
            self.calculate_portfolio_returns()

        return self.portfolio_weights, self.portfolio_returns


"""
Problem 2:

Implement a risk parity strategy as dataframe "rp". Please do "not" include SPY.
"""


class RiskParityPortfolio:

    def __init__(self, exclude, lookback=50):
        self.exclude = exclude
        self.lookback = lookback

    def calculate_weights(self):
        # Get the assets by excluding the specified column
        assets = df.columns[df.columns != self.exclude]

        # Calculate the portfolio weights
        self.portfolio_weights = pd.DataFrame(index=df.index,
                                              columns=df.columns)
        """
        TODO: Complete Task 2 Below
        """
        for i in range(self.lookback + 1, len(df_returns)):
            volatilities = 1 / (df_returns.iloc[i -
                                                self.lookback:i][assets].std())
            weights = volatilities / volatilities.sum()
            self.portfolio_weights.loc[df.index[i], assets] = weights.values
        """
        TODO: Complete Task 2 Above
        """

        self.portfolio_weights.ffill(inplace=True)
        self.portfolio_weights.fillna(0, inplace=True)

    def calculate_portfolio_returns(self):
        # Ensure weights are calculated
        if not hasattr(self, "portfolio_weights"):
            self.calculate_weights()

        # Calculate the portfolio returns
        self.portfolio_returns = df_returns.copy()
        assets = df.columns[df.columns != self.exclude]
        self.portfolio_returns["Portfolio"] = (
            self.portfolio_returns[assets].mul(
                self.portfolio_weights[assets]).sum(axis=1))

    def get_results(self):
        # Ensure portfolio returns are calculated
        if not hasattr(self, "portfolio_returns"):
            self.calculate_portfolio_returns()

        return self.portfolio_weights, self.portfolio_returns


"""
Problem 3:

Implement a Markowitz strategy as dataframe "mv". Please do "not" include SPY.
"""


class MeanVariancePortfolio:

    def __init__(self, exclude, lookback=50, gamma=0):
        self.exclude = exclude
        self.lookback = lookback
        self.gamma = gamma

    def calculate_weights(self):
        # Get the assets by excluding the specified column
        assets = df.columns[df.columns != self.exclude]

        # Calculate the portfolio weights
        self.portfolio_weights = pd.DataFrame(index=df.index,
                                              columns=df.columns)

        for i in range(self.lookback + 1, len(df)):
            R_n = df_returns.copy()[assets].iloc[i - self.lookback:i]
            self.portfolio_weights.loc[df.index[i],
                                       assets] = self.mv_opt(R_n, self.gamma)

        self.portfolio_weights.ffill(inplace=True)
        self.portfolio_weights.fillna(0, inplace=True)

    def mv_opt(self, R_n, gamma):
        Sigma = R_n.cov().values
        mu = R_n.mean().values
        n = len(R_n.columns)

        with gp.Env(empty=True) as env:
            env.setParam("OutputFlag", 0)
            env.setParam("DualReductions", 0)
            env.start()
            with gp.Model(env=env, name="portfolio") as model:
                """
                TODO: Complete Task 3 Below
                """

                # Sample Code: Initialize Decision w and the Objective
                # NOTE: You can modify the following code
                # w = model.addMVar(n, name="w", ub=1)
                # model.setObjective(w.sum(), gp.GRB.MAXIMIZE)

                w = model.addMVar(shape=n, lb=0.0, name="w")
                # objective: maximize (w^T * mu - gamma/2 * w^T * Sigma * w)
                objective = (w @ mu) - (gamma / 2) * (w @ Sigma @ w)
                model.setObjective(objective, gp.GRB.MAXIMIZE)
                model.addConstr(w.sum() == 1.0, name="budget")
                """
                TODO: Complete Task 3 Below
                """
                model.optimize()

                # Check if the status is INF_OR_UNBD (code 4)
                if model.status == gp.GRB.INF_OR_UNBD:
                    print(
                        "Model status is INF_OR_UNBD. Reoptimizing with DualReductions set to 0."
                    )
                elif model.status == gp.GRB.INFEASIBLE:
                    # Handle infeasible model
                    print("Model is infeasible.")
                elif model.status == gp.GRB.INF_OR_UNBD:
                    # Handle infeasible or unbounded model
                    print("Model is infeasible or unbounded.")

                if model.status == gp.GRB.OPTIMAL or model.status == gp.GRB.SUBOPTIMAL:
                    # Extract the solution
                    solution = []
                    for i in range(n):
                        var = model.getVarByName(f"w[{i}]")
                        # print(f"w {i} = {var.X}")
                        solution.append(var.X)

        return solution

    def calculate_portfolio_returns(self):
        # Ensure weights are calculated
        if not hasattr(self, "portfolio_weights"):
            self.calculate_weights()

        # Calculate the portfolio returns
        self.portfolio_returns = df_returns.copy()
        assets = df.columns[df.columns != self.exclude]
        self.portfolio_returns["Portfolio"] = (
            self.portfolio_returns[assets].mul(
                self.portfolio_weights[assets]).sum(axis=1))

    def get_results(self):
        # Ensure portfolio returns are calculated
        if not hasattr(self, "portfolio_returns"):
            self.calculate_portfolio_returns()

        return self.portfolio_weights, self.portfolio_returns


"""
Helper Function:

The following functions will help check your solution,
Please see the following "Performance Check" section
"""


class Helper:

    def __init__(self):
        self.eqw = EqualWeightPortfolio("SPY").get_results()
        self.rp = RiskParityPortfolio("SPY").get_results()
        self.mv_list = [
            MeanVariancePortfolio("SPY").get_results(),
            MeanVariancePortfolio("SPY", gamma=100).get_results(),
            MeanVariancePortfolio("SPY", lookback=100).get_results(),
            MeanVariancePortfolio("SPY", lookback=100,
                                  gamma=100).get_results(),
        ]

    def plot_performance(self, strategy_list=None):
        # Plot cumulative returns
        _, ax = plt.subplots()

        (1 + df_returns["SPY"]).cumprod().plot(ax=ax, label="SPY")
        (1 + self.eqw[1]["Portfolio"]).cumprod().plot(ax=ax,
                                                      label="equal_weight")
        (1 + self.rp[1]["Portfolio"]).cumprod().plot(ax=ax,
                                                     label="risk_parity")

        if strategy_list != None:
            for i, strategy in enumerate(strategy_list):
                (1 + strategy[1]["Portfolio"]).cumprod().plot(
                    ax=ax, label=f"strategy {i+1}")

        ax.set_title("Cumulative Returns")
        ax.set_xlabel("Date")
        ax.set_ylabel("Cumulative Returns")
        ax.legend()
        plt.show()
        return None

    def plot_allocation(self, df_weights):
        df_weights = df_weights.fillna(0).ffill()

        # long only
        df_weights[df_weights < 0] = 0

        # Plotting
        _, ax = plt.subplots()
        df_weights.plot.area(ax=ax)
        ax.set_xlabel("Date")
        ax.set_ylabel("Allocation")
        ax.set_title("Asset Allocation Over Time")
        plt.show()
        return None

    def report_metrics(self):
        df_bl = pd.DataFrame()
        df_bl["EQW"] = pd.to_numeric(self.eqw[1]["Portfolio"], errors="coerce")
        df_bl["RP"] = pd.to_numeric(self.rp[1]["Portfolio"], errors="coerce")
        df_bl["SPY"] = df_returns["SPY"]
        for i, strategy in enumerate(self.mv_list):
            df_bl[f"MV {i+1}"] = pd.to_numeric(strategy[1]["Portfolio"],
                                               errors="coerce")
            """
            NOTE: You can add your strategy here.
            """

        qs.reports.metrics(df_bl, mode="full", display=True)

    def plot_mean_variance_portfolio_performance(self):
        self.plot_performance(self.mv_list)

    def plot_eqw_allocation(self):
        self.plot_allocation(self.eqw[0])

    def plot_rp_allocation(self):
        self.plot_allocation(self.rp[0])

    def plot_mean_variance_allocation(self):
        self.plot_allocation(self.mv_list[0][0])
        self.plot_allocation(self.mv_list[1][0])

    def plot_report_metrics(self):
        self.report_metrics()


"""
Assignment Judge
"""


class AssignmentJudge:

    def __init__(self):
        self.eqw_path = "./Answer/eqw.pkl"
        self.rp_path = "./Answer/rp.pkl"
        self.mv_list_0_path = "./Answer/mv_list_0.pkl"
        self.mv_list_1_path = "./Answer/mv_list_1.pkl"
        self.mv_list_2_path = "./Answer/mv_list_2.pkl"
        self.mv_list_3_path = "./Answer/mv_list_3.pkl"

        self.eqw = EqualWeightPortfolio("SPY").get_results()[0]
        self.rp = RiskParityPortfolio("SPY").get_results()[0]
        self.mv_list = [
            MeanVariancePortfolio("SPY").get_results()[0],
            MeanVariancePortfolio("SPY", gamma=100).get_results()[0],
            MeanVariancePortfolio("SPY", lookback=100).get_results()[0],
            MeanVariancePortfolio("SPY", lookback=100,
                                  gamma=100).get_results()[0],
        ]

    def check_dataframe_similarity(self, df1, df2, tolerance=0.01):
        # Check if the shape, index, and columns of both DataFrames are the same
        if (df1.shape != df2.shape or not df1.index.equals(df2.index)
                or not df1.columns.equals(df2.columns)):
            return False

        # Compare values with allowed relative difference
        for column in df1.columns:
            if (df1[column].dtype.kind in "bifc" and df2[column].dtype.kind
                    in "bifc"):  # Check only numeric types
                if not np.isclose(df1[column], df2[column],
                                  atol=tolerance).all():
                    return False
            else:
                if not (df1[column] == df2[column]).all():
                    return False

        return True

    def compare_dataframe_list(self, std_ans_list, ans_list, tolerance=0.01):
        if len(std_ans_list) != len(ans_list):
            raise ValueError(
                "Both lists must have the same number of DataFrames.")

        results = []
        for df1, df2 in zip(std_ans_list, ans_list):
            result = self.check_dataframe_similarity(df1, df2, tolerance)
            results.append(result)

        return results == [True] * len(results)

    def compare_dataframe(self, df1, df2, tolerance=0.01):
        return self.check_dataframe_similarity(df1, df2, tolerance)

    def check_answer_eqw(self, eqw_dataframe):
        answer_dataframe = pd.read_pickle(self.eqw_path)
        if self.compare_dataframe(answer_dataframe, eqw_dataframe):
            print("Problem 1 Complete - Get 10 Points")
            return 10
        else:
            print("Problem 1 Fail")
        return 0

    def check_answer_rp(self, rp_dataframe):
        answer_dataframe = pd.read_pickle(self.rp_path)
        if self.compare_dataframe(answer_dataframe, rp_dataframe):
            print("Problem 2 Complete - Get 10 Points")
            return 10
        else:
            print("Problem 2 Fail")
        return 0

    def check_answer_mv_list(self, mv_list):
        mv_list_0 = pd.read_pickle(self.mv_list_0_path)
        mv_list_1 = pd.read_pickle(self.mv_list_1_path)
        mv_list_2 = pd.read_pickle(self.mv_list_2_path)
        mv_list_3 = pd.read_pickle(self.mv_list_3_path)
        answer_list = [mv_list_0, mv_list_1, mv_list_2, mv_list_3]
        if self.compare_dataframe_list(answer_list, mv_list):
            print("Problem 3 Complete - Get 15 points")
            return 15
        else:
            print("Problem 3 Fail")
        return 0

    def check_all_answer(self):
        score = 0
        score += self.check_answer_eqw(eqw_dataframe=self.eqw)
        score += self.check_answer_rp(self.rp)
        score += self.check_answer_mv_list(self.mv_list)
        return score


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Introduction to Fintech Assignment 3 Part 1")
    """
    NOTE: For Assignment Judge
    """
    parser.add_argument(
        "--score",
        action="append",
        help="Score for assignment",
    )

    parser.add_argument(
        "--allocation",
        action="append",
        help="Allocation for asset",
    )

    parser.add_argument(
        "--performance",
        action="append",
        help="Performance for portfolio",
    )

    parser.add_argument("--report",
                        action="append",
                        help="Report for evaluation metric")

    args = parser.parse_args()

    judge = AssignmentJudge()
    helper = Helper()

    if args.score:
        if ("eqw" in args.score) or ("rp" in args.score) or ("mv"
                                                             in args.score):
            if "eqw" in args.score:
                judge.check_answer_eqw(judge.eqw)
            if "rp" in args.score:
                judge.check_answer_rp(judge.rp)
            if "mv" in args.score:
                judge.check_answer_mv_list(judge.mv_list)
        elif "all" in args.score:
            print(f"==> totoal Score = {judge.check_all_answer()} <==")
    """
    NOTE: For Allocation
    """
    if args.allocation:
        if "eqw" in args.allocation:
            helper.plot_eqw_allocation()
        if "rp" in args.allocation:
            helper.plot_rp_allocation()
        if "mv" in args.allocation:
            helper.plot_mean_variance_allocation()
    """
    NOTE: For Performance Check
    """
    if args.performance:
        if "mv":
            helper.plot_mean_variance_portfolio_performance()
    """
    NOTE: For Report Metric
    """
    if args.report:
        if "mv" in args.report:
            helper.plot_report_metrics()
