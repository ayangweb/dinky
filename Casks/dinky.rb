cask "dinky" do
  version "2.9.0"
  sha256 "863dd7aef630895caf37f79c3e13a77b0ff6e253f6aa1b14e876f3bf08a1cc53"

  url "https://github.com/heyderekj/dinky/releases/download/v#{version}/Dinky-#{version}.zip"
  name "Dinky"
  desc "Image, video, and PDF compression utility"
  homepage "https://github.com/heyderekj/dinky"

  depends_on macos: ">= :sequoia"

  app "Dinky.app"
end
