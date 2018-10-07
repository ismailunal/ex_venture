defmodule Web.ClassView do
  use Web, :view

  alias Web.Endpoint
  alias Web.Router.Helpers, as: RouteHelpers
  alias Web.SkillView

  def render("index.json", %{classes: classes}) do
    %{
      collection: render_many(classes, __MODULE__, "show.json"),
      links: [
        %{rel: "self", href: RouteHelpers.public_class_url(Endpoint, :index)},
        %{rel: "up", href: RouteHelpers.public_page_url(Endpoint, :index)}
      ]
    }
  end

  def render("index." <> extension, %{classes: classes}) when extension in ["hal", "siren", "jsonapi"] do
    classes
    |> index()
    |> Representer.transform(extension)
  end

  def render("show.json", %{class: class, extended: true}) do
    skills = Enum.map(class.class_skills, & &1.skill)

    %{
      key: class.api_id,
      name: class.name,
      description: class.description,
      skills: render_many(skills, SkillView, "show.json", %{class: true}),
      links: [
        %{rel: "self", href: RouteHelpers.public_class_url(Endpoint, :show, class.id)},
        %{rel: "up", href: RouteHelpers.public_class_url(Endpoint, :index)}
      ]
    }
  end

  def render("show.json", %{class: class}) do
    %{
      key: class.api_id,
      name: class.name,
      description: class.description,
      links: [
        %{rel: "self", href: RouteHelpers.public_class_url(Endpoint, :show, class.id)}
      ]
    }
  end

  def render("show." <> extension, %{class: class}) when extension in ["hal", "siren"] do
    class
    |> show()
    |> Representer.transform(extension)
  end

  defp show(class) do
    %Representer.Item{
      item: Map.delete(render("show.json", %{class: class, extended: false}), :links),
      links: [
        %Representer.Link{rel: "curies", href: "https://exventure.org/rels/{exventure}", title: "exventure", template: true},
        %Representer.Link{rel: "self", href: RouteHelpers.public_class_url(Endpoint, :show, class.id)},
        %Representer.Link{rel: "up", href: RouteHelpers.public_class_url(Endpoint, :index)},
      ],
    }
  end

  defp index(classes) do
    classes = Enum.map(classes, &show/1)

    %Representer.Collection{
      name: "classes",
      items: classes,
      links: [
        %Representer.Link{rel: "self", href: RouteHelpers.public_class_url(Endpoint, :index)},
        %Representer.Link{rel: "up", href: RouteHelpers.public_page_url(Endpoint, :index)}
      ]
    }
  end
end
