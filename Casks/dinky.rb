cask "dinky" do
  version "2.8.0"
  sha256 "6abc39f73b5b9afeb761005b85bfc9b00ef8f73d6ae027ac70bd1dceefe0dd4b"

  url "https://github.com/heyderekj/dinky/releases/download/v#{version}/Dinky-#{version}.zip"
  name "Dinky"
  desc "Image, video, and PDF compression utility"
  homepage "https://github.com/heyderekj/dinky"

  depends_on macos: ">= :sequoia"

  app "Dinky.app"
end
