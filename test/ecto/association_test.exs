defmodule Ecto.AssociationTest do
  use ExUnit.Case, async: true
  doctest Ecto.Association

  import Ecto.Model
  import Ecto.Query, only: [from: 2]

  alias __MODULE__.Author
  alias __MODULE__.Comment
  alias __MODULE__.Permalink
  alias __MODULE__.Post
  alias __MODULE__.Summary
  alias __MODULE__.Email
  alias __MODULE__.Profile

  defmodule Post do
    use Ecto.Model

    schema "posts" do
      has_many :comments, Comment
      has_one :permalink, Permalink
      belongs_to :author, Author
      belongs_to :summary, Summary
    end
  end

  defmodule Comment do
    use Ecto.Model

    schema "comments" do
      belongs_to :post, Post
      has_one :post_author, through: [:post, :author]       # belongs -> belongs
      has_one :post_permalink, through: [:post, :permalink] # belongs -> one
    end
  end

  defmodule Permalink do
    use Ecto.Model

    schema "permalinks" do
    end
  end

  defmodule Author do
    use Ecto.Model

    schema "authors" do
      has_many :posts, Post
      has_many :posts_comments, through: [:posts, :comments]    # many -> many
      has_many :posts_permalinks, through: [:posts, :permalink] # many -> one
      has_many :emails, {"users_emails", Email}
      has_one :profile, {"users_profiles", Profile}
    end
  end

  defmodule Summary do
    use Ecto.Model

    schema "summaries" do
      has_one :post, Post
      has_one :post_author, through: [:post, :author]        # one -> belongs
      has_many :post_comments, through: [:post, :comments]   # one -> many
    end
  end

  defmodule Email do
    use Ecto.Model

    schema "emails" do
      belongs_to :author, {"post_authors", Author}
    end
  end

  defmodule Profile do
    use Ecto.Model

    schema "profiles" do
    end
  end

  ## Unit tests

  test "has many" do
    assoc = Post.__schema__(:association, :comments)

    assert inspect(Ecto.Association.Has.joins_query(assoc)) ==
           inspect(from p in Post, join: c in Comment, on: c.post_id == p.id)

    assert inspect(Ecto.Association.Has.assoc_query(assoc, [])) ==
           inspect(from c in Comment, where: c.post_id in ^[])

    assert inspect(Ecto.Association.Has.assoc_query(assoc, [1, 2, 3])) ==
           inspect(from c in Comment, where: c.post_id in ^[1, 2, 3])
  end

  test "has many model with specified source" do
    assoc = Author.__schema__(:association, :emails)

    assert inspect(Ecto.Association.Has.joins_query(assoc)) ==
           inspect(from a in Author, join: e in {"users_emails", Email}, on: e.author_id == a.id)

    assert inspect(Ecto.Association.Has.assoc_query(assoc, [])) ==
           inspect(from e in {"users_emails", Email}, where: e.author_id in ^[])

    assert inspect(Ecto.Association.Has.assoc_query(assoc, [1, 2, 3])) ==
           inspect(from e in {"users_emails", Email}, where: e.author_id in ^[1, 2, 3])
  end

  test "has one" do
    assoc = Post.__schema__(:association, :permalink)

    assert inspect(Ecto.Association.Has.joins_query(assoc)) ==
           inspect(from p in Post, join: c in Permalink, on: c.post_id == p.id)

    assert inspect(Ecto.Association.Has.assoc_query(assoc, [])) ==
           inspect(from c in Permalink, where: c.post_id in ^[])

    assert inspect(Ecto.Association.Has.assoc_query(assoc, [1, 2, 3])) ==
           inspect(from c in Permalink, where: c.post_id in ^[1, 2, 3])
  end

  test "has one model with specified source" do
    assoc = Author.__schema__(:association, :profile)

    assert inspect(Ecto.Association.Has.joins_query(assoc)) ==
           inspect(from a in Author, join: p in {"users_profiles", Profile}, on: p.author_id == a.id)

    assert inspect(Ecto.Association.Has.assoc_query(assoc, [])) ==
           inspect(from p in {"users_profiles", Profile}, where: p.author_id in ^[])

    assert inspect(Ecto.Association.Has.assoc_query(assoc, [1, 2, 3])) ==
           inspect(from p in {"users_profiles", Profile}, where: p.author_id in ^[1, 2, 3])
  end

  test "belongs to" do
    assoc = Post.__schema__(:association, :author)

    assert inspect(Ecto.Association.Has.joins_query(assoc)) ==
           inspect(from p in Post, join: a in Author, on: a.id == p.author_id)

    assert inspect(Ecto.Association.Has.assoc_query(assoc, [])) ==
           inspect(from a in Author, where: a.id in ^[])

    assert inspect(Ecto.Association.Has.assoc_query(assoc, [1, 2, 3])) ==
           inspect(from a in Author, where: a.id in ^[1, 2, 3])
  end

  test "belongs to model with specified source" do
    assoc = Email.__schema__(:association, :author)

    assert inspect(Ecto.Association.Has.joins_query(assoc)) ==
           inspect(from e in Email, join: a in {"post_authors", Author}, on: a.id == e.author_id)

    assert inspect(Ecto.Association.Has.assoc_query(assoc, [])) ==
           inspect(from a in {"post_authors", Author}, where: a.id in ^[])

    assert inspect(Ecto.Association.Has.assoc_query(assoc, [1, 2, 3])) ==
           inspect(from a in {"post_authors", Author}, where: a.id in ^[1, 2, 3])
  end

  test "has many through many to many" do
    assoc = Author.__schema__(:association, :posts_comments)

    assert inspect(Ecto.Association.HasThrough.joins_query(assoc)) ==
           inspect(from a in Author, join: p in assoc(a, :posts), join: c in assoc(p, :comments))

    assert inspect(Ecto.Association.HasThrough.assoc_query(assoc, [1,2,3])) ==
           inspect(from c in Comment, join: p in Post, on: c.post_id == p.id,
                        where: p.author_id in ^[1, 2, 3], distinct: true, select: c)
  end

  test "has many through many to one" do
    assoc = Author.__schema__(:association, :posts_permalinks)

    assert inspect(Ecto.Association.HasThrough.joins_query(assoc)) ==
           inspect(from a in Author, join: p in assoc(a, :posts), join: c in assoc(p, :permalink))

    assert inspect(Ecto.Association.HasThrough.assoc_query(assoc, [1,2,3])) ==
           inspect(from l in Permalink, join: p in Post, on: l.post_id == p.id,
                        where: p.author_id in ^[1, 2, 3], distinct: true, select: l)
  end

  test "has one through belongs to belongs" do
    assoc = Comment.__schema__(:association, :post_author)

    assert inspect(Ecto.Association.HasThrough.joins_query(assoc)) ==
           inspect(from c in Comment, join: p in assoc(c, :post), join: a in assoc(p, :author))

    assert inspect(Ecto.Association.HasThrough.assoc_query(assoc, [1,2,3])) ==
           inspect(from a in Author, join: p in Post, on: a.id == p.author_id,
                        where: p.id in ^[1, 2, 3], distinct: true, select: a)
  end

  test "has one through belongs to one" do
    assoc = Comment.__schema__(:association, :post_permalink)

    assert inspect(Ecto.Association.HasThrough.joins_query(assoc)) ==
           inspect(from c in Comment, join: p in assoc(c, :post), join: l in assoc(p, :permalink))

    assert inspect(Ecto.Association.HasThrough.assoc_query(assoc, [1,2,3])) ==
           inspect(from l in Permalink, join: p in Post, on: l.post_id == p.id,
                        where: p.id in ^[1, 2, 3], distinct: true, select: l)
  end

  test "has many through one to many" do
    assoc = Summary.__schema__(:association, :post_comments)

    assert inspect(Ecto.Association.HasThrough.joins_query(assoc)) ==
           inspect(from s in Summary, join: p in assoc(s, :post), join: c in assoc(p, :comments))

    assert inspect(Ecto.Association.HasThrough.assoc_query(assoc, [1,2,3])) ==
           inspect(from c in Comment, join: p in Post, on: c.post_id == p.id,
                        where: p.summary_id in ^[1, 2, 3], distinct: true, select: c)
  end

  test "has one through one to belongs" do
    assoc = Summary.__schema__(:association, :post_author)

    assert inspect(Ecto.Association.HasThrough.joins_query(assoc)) ==
           inspect(from s in Summary, join: p in assoc(s, :post), join: a in assoc(p, :author))

    assert inspect(Ecto.Association.HasThrough.assoc_query(assoc, [1,2,3])) ==
           inspect(from a in Author, join: p in Post, on: a.id == p.author_id,
                        where: p.summary_id in ^[1, 2, 3], distinct: true, select: a)
  end

  ## Integration tests through Ecto.Model

  test "build/2" do
    assert build(%Post{id: 1}, :comments) ==
           %Comment{post_id: 1}

    assert build(%Summary{id: 1}, :post) ==
           %Post{summary_id: 1}

    assert build(%Comment{post_id: 1}, :post) ==
           %Post{id: nil}

    assert_raise ArgumentError, ~r"cannot build through association :post_author", fn ->
      build(%Comment{}, :post_author)
    end
  end

  test "assoc/2" do
    assert inspect(assoc(%Post{id: 1}, :comments)) ==
           inspect(from c in Comment, where: c.post_id in ^[1])

    assert inspect(assoc([%Post{id: 1}, %Post{id: 2}], :comments)) ==
           inspect(from c in Comment, where: c.post_id in ^[1, 2])
  end

  test "assoc/2 filters nil ids" do
    assert inspect(assoc([%Post{id: 1}, %Post{id: 2}, %Post{}], :comments)) ==
           inspect(from c in Comment, where: c.post_id in ^[1, 2])
  end

  test "assoc/2 fails on empty list" do
    assert_raise ArgumentError, ~r"cannot retrieve association :whatever for empty list", fn ->
      assoc([], :whatever)
    end
  end

  test "assoc/2 fails on missing association" do
    assert_raise ArgumentError, ~r"does not have association :whatever", fn ->
      assoc([%Post{}], :whatever)
    end
  end

  test "assoc/2 fails on heterogeneous collections" do
    assert_raise ArgumentError, ~r"expected a homogeneous list containing the same struct", fn ->
      assoc([%Post{}, %Comment{}], :comments)
    end
  end

  test "Ecto.Association.loaded?/1 returns false if association is not loaded" do
    # refute Ecto.Association.loaded?(%Post{}.comments)
    refute Ecto.Association.loaded?(%Post{}.comments)
  end

  test "Ecto.Association.loaded?/1 returns true if association is loaded" do
    assert Ecto.Association.loaded?(%Post{comments: []}.comments)
  end

  ## Preloader

  alias Ecto.Repo.Preloader

  test "preload: normalizer" do
    assert Preloader.normalize(:foo, [], []) == [foo: []]
    assert Preloader.normalize([foo: :bar], [], []) == [foo: [bar: []]]
    assert Preloader.normalize([foo: [:bar, baz: :bat], this: :that], [], []) ==
           [this: [that: []], foo: [baz: [bat: []], bar: []]]
  end

  test "preload: raises on assoc conflict" do
    assert_raise ArgumentError, ~r"cannot preload association `:foo`", fn ->
      Preloader.normalize(:foo, [foo: []], [])
    end
  end

  test "preload: raises on invalid preload" do
    assert_raise ArgumentError, ~r"invalid preload `123` in `123`", fn ->
      Preloader.normalize(123, [], 123)
    end
  end

  defp expand(model, preloads) do
    Preloader.expand(model, Preloader.normalize(preloads, [], preloads), [])
  end

  test "preload: expand" do
    assert [{:comments, {:assoc, %Ecto.Association.Has{}, :post_id}, []},
            {:permalink, {:assoc, %Ecto.Association.Has{}, :post_id}, []}] =
           expand(Post, [:comments, :permalink])

    assert [{:post, {:assoc, %Ecto.Association.BelongsTo{}, :id},
              [author: [], permalink: []]}] =
           expand(Comment, [:post, post: :author, post: :permalink])

    assert [{:post, {:assoc, %Ecto.Association.BelongsTo{}, :id},
             [author: [], permalink: []]}] =
           expand(Comment, [:post, post: :author, post: :permalink])

    assert [{:posts, {:assoc, %Ecto.Association.Has{}, :author_id}, [comments: [post: []]]},
            {:posts_comments, {:through, %Ecto.Association.HasThrough{}, [:posts, :comments]}, []}] =
           expand(Author, [posts_comments: :post])

    assert [{:posts, {:assoc, %Ecto.Association.Has{}, :author_id}, [comments: _, comments: _]},
           {:posts_comments, {:through, %Ecto.Association.HasThrough{}, [:posts, :comments]}, []}] =
           expand(Author, [:posts, posts_comments: :post, posts: [comments: :post]])
  end
end
