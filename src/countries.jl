using HTTP, JSON3, CSV

parse_country(obj) = (id = obj.id, name = obj.name, incomde = obj.incomeLevel.id)
data = "https://api.worldbank.org/v2/country?region=SAS&format=json" |>
    HTTP.get |>
    (response -> response.body) |>
    String |>
    JSON3.read |>
    last |>
    (obj -> CSV.write(joinpath("data", "countries.csv"),
                      parse_country(elem) for elem in obj))
