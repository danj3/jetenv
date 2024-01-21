import Config

if Mix.env() in [:test, :dev] do
  config :jetenv, :string_data,
    simple: "hello",
    newlines: "hello\nthere",
    newlines2: "hello
  there",
    quotes: "with \"quotes\"",
    tabs: "this \t tab",
    long_text: """
    once upon a time
    there were three bears
    a momma bear
    a papa bear
    and a baby bear
    """
end
