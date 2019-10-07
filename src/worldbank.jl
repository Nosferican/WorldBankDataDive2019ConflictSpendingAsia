using HTTP, JSON3, CSV, DataFrames

parse_country(obj) = (id = obj.id, name = obj.name, incomde = obj.incomeLevel.id)
function parse_datum(obj)
    (name = obj.countryiso3code,
     indicator = obj.indicator.id,
     date = obj.date,
     value = isnothing(obj.value) ? missing : obj.value)
end
function parse_data(;countries = countries, years = "2009:2019", indicator = nothing)
    isnothing(indicator) && throw(ArgumentError("Please provide an indicator"))
    string("http://api.worldbank.org/v2/country/$countries/",
                  "indicator/$indicator?",
                  "date=2009:2019&per_page=1&format=json") |>
        HTTP.get |>
        (response -> response.body) |>
        String |>
        JSON3.read |>
        (obj -> obj[1].total) |>
        (total -> string("http://api.worldbank.org/v2/country/$countries/",
                      "indicator/$indicator?",
                      "date=2009:2019&per_page=$total&format=json")) |>
        HTTP.get |>
        (response -> response.body) |>
        String |>
        JSON3.read |>
        last |>
        (obj -> [ parse_data(elem) for elem in obj ])
end
data = "https://api.worldbank.org/v2/country?region=SAS&format=json" |>
    HTTP.get |>
    (response -> response.body) |>
    String |>
    JSON3.read |>
    last |>
    (obj -> CSV.write(joinpath("data", "countries.csv"),
                      parse_country(elem) for elem in obj))
countries = CSV.File(joinpath("data", "countries.csv")) |>
    (obj -> getproperty.(obj, :id)) |>
    (obj -> join(obj, ';'))
indicators = CSV.read(joinpath("data", "indicators.tsv")) |>
    (obj -> obj.code)
output = reduce(vcat,
                parse_data(countries = countries,
                           indicator = indicator) for indicator in indicators)
CSV.write(joinpath("data", "worldbank.tsv"),
          output,
          delim = '\t')
