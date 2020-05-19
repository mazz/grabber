defmodule GrabberWeb.PageController do
  use GrabberWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
