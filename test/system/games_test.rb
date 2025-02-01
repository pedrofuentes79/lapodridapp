require "application_system_test_case"

class GamesTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit "/"

    assert_selector "h1", text: "LaPodridApp"

    click_button "Agregar jugador"

    fill_in "Jugador 1", with: "Aurora"
    fill_in "Jugador 2", with: "Pedro"
    fill_in "Jugador 3", with: "León"

    click_button "Agregar ronda"

    fill_in "Round 1", with: "4"
    fill_in "Round 2", with: "5"

    all('input[type="checkbox"]')[1].check

    click_button "Empezar juego"

    assert_selector "h2", text: "Leaderboard"
  end
end
