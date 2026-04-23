cask "dinky" do
  version "2.7.12"
  sha256 "e01ea47d75b736bd928cfc0e9d081fb46cf2d2c6940a6226a051a49fe01a9b15"

  url "https://github.com/heyderekj/dinky/releases/download/v#{version}/Dinky-#{version}.zip"
  name "Dinky"
  desc "Image, video, and PDF compression utility"
  homepage "https://github.com/heyderekj/dinky"

  depends_on macos: ">= :sequoia"

  app "Dinky.app"
end
