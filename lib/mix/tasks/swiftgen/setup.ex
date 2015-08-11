defmodule Mix.Tasks.Swiftgen.Setup do
  use Mix.Task

  @shortdoc "Setup swift code base"

  @moduledoc """
  Generates swift code base into your iOS project.

  ## Example
      mix swiftgen.setup /path/to/your/swift/directory http://your_base_url.com

  The first argument is the directory which you want to generate code base in your iOS project,
  and second argument is your host URL.
  """

  def run(args) do
  end

end
