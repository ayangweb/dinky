cask "dinky" do
  version "2.9.1"
  sha256 "a72f232c34501d7117b2c2424c289c0eb306477df867aba3bced3e92f32b7c16"

  url "https://github.com/heyderekj/dinky/releases/download/v#{version}/Dinky-#{version}.zip"
  name "Dinky"
  desc "Image, video, audio, and PDF compression utility"
  homepage "https://github.com/heyderekj/dinky"

  depends_on macos: ">= :sequoia"

  app "Dinky.app"
end
