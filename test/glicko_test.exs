defmodule GlickoTest do
  use ExUnit.Case

  alias Glicko.{
    Player,
    Result
  }

  doctest Glicko

  describe "new rating" do
    test "with results" do
      player_before_results_v1 = %Player.V1{rating: 1500, rating_deviation: 200}
      player_before_results_v2 = Player.to_v2(player_before_results_v1)

      results = [
        Result.new(%Player.V1{rating: 1400, rating_deviation: 30}, :win),
        Result.new(%Player.V1{rating: 1550, rating_deviation: 100}, :loss),
        Result.new(%Player.V1{rating: 1700, rating_deviation: 300}, :loss)
      ]

      player_after_results_v2 =
        %Player.V2{} = Glicko.new_rating(player_before_results_v2, results, system_constant: 0.5)

      player_after_results_v1 = Player.to_v1(player_after_results_v2)

      assert_in_delta player_after_results_v1.rating,
                      player_before_results_v1.rating - 35.94,
                      1.0e-2

      assert_in_delta player_after_results_v1.rating_deviation,
                      player_before_results_v1.rating_deviation - 48.48,
                      1.0e-2

      assert_in_delta player_after_results_v2.volatility,
                      player_before_results_v2.volatility - 0.001,
                      1.0e-3
    end

    test "no results" do
      initial_rating_deviation = 200

      player = %Player.V1{
        rating: 1500,
        rating_deviation: initial_rating_deviation
      }

      player_after_no_results =
        player
        |> Glicko.new_rating(_results = [])
        |> Player.to_v1()

      assert_in_delta player_after_no_results.rating_deviation,
                      initial_rating_deviation + 0.2714,
                      1.0e-4
    end
  end

  describe "win probability" do
    test "with same ratings" do
      assert Glicko.win_probability(%Player.V1{}, %Player.V1{}) == 0.5
    end

    test "with better opponent" do
      assert Glicko.win_probability(%Player.V1{rating: 1500}, %Player.V1{rating: 1600}) <
               0.5
    end

    test "with better player" do
      assert Glicko.win_probability(%Player.V1{rating: 1600}, %Player.V1{rating: 1500}) >
               0.5
    end
  end

  describe "draw probability" do
    test "with same ratings" do
      assert Glicko.draw_probability(%Player.V1{}, %Player.V1{}) == 1
    end

    test "with better opponent" do
      assert Glicko.draw_probability(%Player.V1{rating: 1500}, %Player.V1{rating: 1600}) < 1
    end

    test "with better player" do
      assert Glicko.draw_probability(%Player.V1{rating: 1600}, %Player.V1{rating: 1500}) < 1
    end
  end
end
