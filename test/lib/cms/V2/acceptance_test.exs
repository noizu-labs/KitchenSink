#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.AcceptanceTest do
  use ExUnit.Case, async: false
  use Amnesia
  use Noizu.Cms.Database

  #----------------
  # Import
  #----------------
  import Mock

  #----------------
  # Require
  #----------------
  require Logger

  #----------------
  # Aliases
  #----------------
  alias Noizu.Cms.V2.Database.ArticleTable
  alias Noizu.Cms.V2.Database.IndexTable
  alias Noizu.Cms.V2.Database.TagTable
  alias Noizu.Cms.V2.Database.VersionSequencerTable
  alias Noizu.Cms.V2.Database.VersionTable
  alias Noizu.Cms.V2.Database.Version.RevisionTable

  alias Noizu.Support.Cms.V2.Database.MockArticleTable
  alias Noizu.Support.Cms.V2.Database.MockIndexTable
  alias Noizu.Support.Cms.V2.Database.MockTagTable
  alias Noizu.Support.Cms.V2.Database.MockVersionSequencerTable
  alias Noizu.Support.Cms.V2.Database.MockVersionTable
  alias Noizu.Support.Cms.V2.Database.Version.MockRevisionTable

  #----------------
  # Macros
  #----------------
  @context Noizu.ElixirCore.CallingContext.admin()

  #==============================================
  # Acceptance Tests
  #==============================================

  #----------------------------------------
  # Default Version Provider
  #----------------------------------------
  @tag :cms
  @tag :cms_version_provider
  test "Create Version" do
    assert true == true
  end

  @tag :cms
  @tag :cms_version_provider
  test "Edit Version" do
    assert true == true
  end

  @tag :cms
  @tag :cms_version_provider
  test "Delete Version" do
    assert true == true
  end

  @tag :cms
  @tag :cms_version_provider
  test "Compress Version" do
    assert true == true
  end

  @tag :cms
  @tag :cms_version_provider
  test "Expand Version" do
    assert true == true
  end

  @tag :cms
  @tag :cms_version_provider
  test "Version History" do
    assert true == true
  end

  #----------------------------------------
  # Default Repo Implementation
  #----------------------------------------

  @tag :cms
  @tag :cms_repo_provider
  test "Get Articles By Status" do
    assert true == true
  end

  @tag :cms
  @tag :cms_repo_provider
  test "Get Articles By Type" do
    assert true == true
  end

  @tag :cms
  @tag :cms_repo_provider
  test "Get Articles By Module" do
    assert true == true
  end

  @tag :cms
  @tag :cms_repo_provider
  test "Get Articles By Editor" do
    assert true == true
  end

  @tag :cms
  @tag :cms_repo_provider
  test "Get Articles By Tag" do
    assert true == true
  end

  @tag :cms
  @tag :cms_repo_provider
  test "Get Articles By Created On Date" do
    assert true == true
  end

  @tag :cms
  @tag :cms_repo_provider
  test "Get Articles By Modified On Date" do
    assert true == true
  end

  @tag :cms
  @tag :cms_repo_provider
  test "Get Article Version History" do
    assert true == true
  end

  @tag :cms
  @tag :cms_repo_provider
  test "Get Article Version" do
    assert true == true
  end

  @tag :cms
  @tag :cms_repo_provider
  test "Get Article Versions" do
    assert true == true
  end

  @tag :cms
  @tag :cms_repo_provider
  test "Create Article Repo Hooks" do
    assert true == true
  end

  @tag :cms
  @tag :cms_repo_provider
  test "Edit Article Repo Hooks" do
    assert true == true
  end

  @tag :cms
  @tag :cms_repo_provider
  test "Get Article Repo Hooks" do
    assert true == true
  end

  @tag :cms
  @tag :cms_repo_provider
  test "Delete Article Repo Hooks" do
    assert true == true
  end

  #----------------------------------------
  # Markdown (Move)
  #----------------------------------------
  @tag :cms
  @tag :markdown
  test "Compress Markdown Record" do
    assert true == true
  end

  @tag :cms
  @tag :markdown
  test "Expand Markdown Record" do
    assert true == true
  end

  @tag :cms
  @tag :markdown
  test "Render Markdown record" do
    assert true == true
  end


  #----------------------------------------
  # CMS Proto
  #----------------------------------------
  @tag :cms
  @tag :cms_protocol
  test "CMS Protocol - tags" do
    assert true == true
  end

  @tag :cms
  @tag :cms_protocol
  test "CMS Protocol - set_version" do
    assert true == true
  end

  @tag :cms
  @tag :cms_protocol
  test "CMS Protocol - get_version" do
    assert true == true
  end

  @tag :cms
  @tag :cms_protocol
  test "CMS Protocol - prepare_version" do
    assert true == true
  end

  @tag :cms
  @tag :cms_protocol
  test "CMS Protocol - expand_version" do
    assert true == true
  end

  @tag :cms
  @tag :cms_protocol
  test "CMS Protocol - index_details" do
    assert true == true
  end

  #----------------------------------------
  # Built In CMS Types
  #----------------------------------------
  # @TODO - we will go from top to bottom. Setup new entries, then go in to make sure all supporting records are correctly populated.

  @tag :cms
  @tag :cms_built_in
  test "Article Polymorphism Support" do
    assert true == true
  end

  @tag :cms
  @tag :cms_built_in
  test "Article - Create Should Populate Version, Revision, Index and Tag Tables." do
    with_mocks([
      {ArticleTable, [:passthrough], MockArticleTable.strategy()},
      {IndexTable, [:passthrough], MockIndexTable.strategy()},
      {TagTable, [:passthrough], MockTagTable.strategy()},
      {VersionSequencerTable, [:passthrough], MockVersionSequencerTable.strategy()},
      {VersionTable, [:passthrough], MockVersionTable.strategy()},
      {RevisionTable, [:passthrough], MockRevisionTable.strategy()},
    ]) do

      Noizu.Support.Cms.V2.Database.MnesiaEmulator.reset()

      # Setup Article
      post = %Noizu.Cms.V2.Article.PostEntity{
        title: %Noizu.MarkdownField{markdown: "My Post"},
        body: %Noizu.MarkdownField{markdown: "My Post Contents"},
        attributes: %{},
        article_info: %Noizu.Cms.V2.Article.Info{tags: MapSet.new(["test", "apple"])}
      }
      post = Noizu.Cms.V2.ArticleRepo.create!(post, @context)

      # Verify Identifier Created
      {:revision, {aid, _version, _revision}} = post.identifier
      assert is_integer(aid) == true
      assert post.identifier == {:revision, {aid, {1}, 1}}

      # Verify article_info fleshed out.
      article_ref = {:ref, Noizu.Cms.V2.ArticleEntity, aid}
      assert post.article_info.article == article_ref

      # Verify Created On/Modified On dates.
      assert post.article_info.created_on != nil
      assert post.article_info.modified_on != nil

      # Verify Version Info
      assert post.article_info.version == {:ref, Noizu.Cms.V2.VersionEntity, {post.article_info.article, {1}}}

      # Verify Parent Info
      assert post.article_info.parent == nil

      # Verify Revision
      assert post.article_info.revision == {:ref, Noizu.Cms.V2.Version.RevisionEntity, {post.article_info.version, 1}}

      # Verify Type  Set correctly
      assert post.article_info.type == :post

      # Verify Version Record
      version_key = elem(post.article_info.version, 2)
      version_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(VersionTable, version_key, :error)
      #assert version_record.entity.record.body.markdown == "My Post Contents"
      assert version_record.entity.revision == post.article_info.revision
      assert version_record.entity.parent == nil
      assert version_record.entity.article == article_ref

      # Verify Revision Record
      revision_key = elem(post.article_info.revision, 2)
      revision_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(RevisionTable, revision_key, :error)
      assert revision_record.entity.record.body.markdown == "My Post Contents"
      assert revision_record.entity.version == post.article_info.version
      assert revision_record.entity.article == article_ref

      # Verify Tags
      tags = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(TagTable, article_ref, [])
            |> Enum.map(&(&1.tag))
      assert Enum.member?(tags, "apple") == true
      assert Enum.member?(tags, "test") == true

      # Verify Index Record
      index_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(IndexTable, article_ref, :error)
      assert index_record.article == {:ref, Noizu.Cms.V2.ArticleEntity, aid}
      assert index_record.active_version == post.article_info.version
      assert index_record.created_on == post.article_info.created_on
      assert index_record.modified_on == post.article_info.modified_on
      assert index_record.module == Noizu.Cms.V2.Article.PostEntity
      assert index_record.type == :post
      assert index_record.status == :pending
    end
  end

  @tag :cms
  @tag :cms_built_in
  test "Article - Updating an active record should cause the Index and Tag table to update as well." do
    with_mocks([
      {ArticleTable, [:passthrough], MockArticleTable.strategy()},
      {IndexTable, [:passthrough], MockIndexTable.strategy()},
      {TagTable, [:passthrough], MockTagTable.strategy()},
      {VersionSequencerTable, [:passthrough], MockVersionSequencerTable.strategy()},
      {VersionTable, [:passthrough], MockVersionTable.strategy()},
      {RevisionTable, [:passthrough], MockRevisionTable.strategy()},
    ]) do
      Noizu.Support.Cms.V2.Database.MnesiaEmulator.reset()

      # Setup Article
      post = %Noizu.Cms.V2.Article.PostEntity{
        title: %Noizu.MarkdownField{markdown: "My Post"},
        body: %Noizu.MarkdownField{markdown: "My Post Contents"},
        attributes: %{},
        article_info: %Noizu.Cms.V2.Article.Info{tags: MapSet.new(["test", "apple"])}
      }
      post = Noizu.Cms.V2.ArticleRepo.create!(post, @context)
      {:revision, {aid, _version, _revision}} = post.identifier
      article_ref = {:ref, Noizu.Cms.V2.ArticleEntity, aid}
      index_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(IndexTable, article_ref, :error)
      assert index_record != :error

      _revised_post = %Noizu.Cms.V2.Article.PostEntity{post|
        title: %Noizu.MarkdownField{markdown: "My Updated Post"},
        body: %Noizu.MarkdownField{markdown: "My Updated Contents"},
        attributes: %{},
        article_info: %Noizu.Cms.V2.Article.Info{post.article_info| tags: MapSet.new(["hello", "steve"]), status: :approved, editor: :test}
      } |> Noizu.Cms.V2.ArticleRepo.update!(@context)

      revised_index_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(IndexTable, article_ref, :error)

      # Verify Index Updated
      assert revised_index_record.editor == :test

      # Verify Tag Update.
      tags = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(TagTable, article_ref, [])
             |> Enum.map(&(&1.tag))

      assert Enum.member?(tags, "hello") == true
      assert Enum.member?(tags, "steve") == true
      assert Enum.member?(tags, "apple") == false
      assert Enum.member?(tags, "test") == false

    end
  end

  @tag :cms
  @tag :cms_built_in
  test "Article - User should be able to create new revisions." do
    with_mocks([
      {ArticleTable, [:passthrough], MockArticleTable.strategy()},
      {IndexTable, [:passthrough], MockIndexTable.strategy()},
      {TagTable, [:passthrough], MockTagTable.strategy()},
      {VersionSequencerTable, [:passthrough], MockVersionSequencerTable.strategy()},
      {VersionTable, [:passthrough], MockVersionTable.strategy()},
      {RevisionTable, [:passthrough], MockRevisionTable.strategy()},
    ]) do
      Noizu.Support.Cms.V2.Database.MnesiaEmulator.reset()

      # Setup Article
      post = %Noizu.Cms.V2.Article.PostEntity{
        title: %Noizu.MarkdownField{markdown: "My Post"},
        body: %Noizu.MarkdownField{markdown: "My Post Contents"},
        attributes: %{},
        article_info: %Noizu.Cms.V2.Article.Info{tags: MapSet.new(["test", "apple"])}
      }
      post = Noizu.Cms.V2.ArticleRepo.create!(post, @context)
      {:revision, {aid, _version, _revision}} = post.identifier
      article_ref = {:ref, Noizu.Cms.V2.ArticleEntity, aid}


      post_v2 = %Noizu.Cms.V2.Article.PostEntity{post|
                       title: %Noizu.MarkdownField{markdown: "My Updated Post"},
                       body: %Noizu.MarkdownField{markdown: "My Updated Contents"},
                       attributes: %{},
                       article_info: %Noizu.Cms.V2.Article.Info{post.article_info| tags: MapSet.new(["hello", "steve"]), status: :approved, editor: :test}
                     } |> Noizu.Cms.V2.ArticleRepo.new_revision!(@context)

      # Verify New Revision Created.
      revision_key = elem(post_v2.article_info.revision, 2)
      revision_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(RevisionTable, revision_key, :error)
      revision = revision_record.entity
      assert revision.editor == :test
      assert revision.status == :approved
      assert revision.identifier ==  {{:ref, Noizu.Cms.V2.VersionEntity, {article_ref, {1}}}, 2}

      # Verify Version Correct in post_v2
      assert post_v2.article_info.version == post.article_info.version


      # Verify Index Not Updated
      index_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(IndexTable, article_ref, :error)
      assert index_record.editor != :test

      # Verify Tag Not Updated.
      tags = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(TagTable, article_ref, [])
             |> Enum.map(&(&1.tag))
      assert Enum.member?(tags, "hello") == false
      assert Enum.member?(tags, "steve") == false
      assert Enum.member?(tags, "apple") == true
      assert Enum.member?(tags, "test") == true
    end
  end


  @tag :cms
  @tag :cms_built_in
  test "Article - User should be able to create new versions." do
    with_mocks([
      {ArticleTable, [:passthrough], MockArticleTable.strategy()},
      {IndexTable, [:passthrough], MockIndexTable.strategy()},
      {TagTable, [:passthrough], MockTagTable.strategy()},
      {VersionSequencerTable, [:passthrough], MockVersionSequencerTable.strategy()},
      {VersionTable, [:passthrough], MockVersionTable.strategy()},
      {RevisionTable, [:passthrough], MockRevisionTable.strategy()},
    ]) do
      Noizu.Support.Cms.V2.Database.MnesiaEmulator.reset()

      # Setup Article
      post = %Noizu.Cms.V2.Article.PostEntity{
        title: %Noizu.MarkdownField{markdown: "My Post"},
        body: %Noizu.MarkdownField{markdown: "My Post Contents"},
        attributes: %{},
        article_info: %Noizu.Cms.V2.Article.Info{tags: MapSet.new(["test", "apple"])}
      }
      post = Noizu.Cms.V2.ArticleRepo.create!(post, @context)
      {:revision, {aid, _version, _revision}} = post.identifier
      article_ref = {:ref, Noizu.Cms.V2.ArticleEntity, aid}


      post_v2 = %Noizu.Cms.V2.Article.PostEntity{post|
                  title: %Noizu.MarkdownField{markdown: "My Updated Post"},
                  body: %Noizu.MarkdownField{markdown: "My Updated Contents"},
                  attributes: %{},
                  article_info: %Noizu.Cms.V2.Article.Info{post.article_info| tags: MapSet.new(["hello", "steve"]), status: :approved, editor: :test}
                } |> Noizu.Cms.V2.ArticleRepo.new_version!(@context)

      # Verify New Revision Created.
      revision_key = elem(post_v2.article_info.revision, 2)
      revision_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(RevisionTable, revision_key, :error)
      revision = revision_record.entity
      assert revision.editor == :test
      assert revision.status == :approved
      assert revision.identifier ==  {{:ref, Noizu.Cms.V2.VersionEntity, {article_ref, {1, 1}}}, 1}

      # Verify parent and version updated.
      # Verify Version Correct in post_v2
      assert post_v2.article_info.parent == post.article_info.version
      assert post_v2.article_info.version == {:ref, Noizu.Cms.V2.VersionEntity, {article_ref, {1, 1}}}

      # Verify Index Not Updated
      index_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(IndexTable, article_ref, :error)
      assert index_record.editor != :test

      # Verify Tag Not Updated.
      tags = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(TagTable, article_ref, [])
             |> Enum.map(&(&1.tag))
      assert Enum.member?(tags, "hello") == false
      assert Enum.member?(tags, "steve") == false
      assert Enum.member?(tags, "apple") == true
      assert Enum.member?(tags, "test") == true
    end
  end


  @tag :cms
  @tag :cms_built_in
  test "Article - User should be able to create multiple versions based on a single parent." do
    with_mocks([
      {ArticleTable, [:passthrough], MockArticleTable.strategy()},
      {IndexTable, [:passthrough], MockIndexTable.strategy()},
      {TagTable, [:passthrough], MockTagTable.strategy()},
      {VersionSequencerTable, [:passthrough], MockVersionSequencerTable.strategy()},
      {VersionTable, [:passthrough], MockVersionTable.strategy()},
      {RevisionTable, [:passthrough], MockRevisionTable.strategy()},
    ]) do
      Noizu.Support.Cms.V2.Database.MnesiaEmulator.reset()

      # Setup Article
      post = %Noizu.Cms.V2.Article.PostEntity{
        title: %Noizu.MarkdownField{markdown: "My Post"},
        body: %Noizu.MarkdownField{markdown: "My Post Contents"},
        attributes: %{},
        article_info: %Noizu.Cms.V2.Article.Info{tags: MapSet.new(["test", "apple"])}
      }
      post = Noizu.Cms.V2.ArticleRepo.create!(post, @context)
      {:revision, {aid, _version, _revision}} = post.identifier
      article_ref = {:ref, Noizu.Cms.V2.ArticleEntity, aid}


      post_v2 = %Noizu.Cms.V2.Article.PostEntity{post|
                  title: %Noizu.MarkdownField{markdown: "My Updated Post"},
                  body: %Noizu.MarkdownField{markdown: "My Updated Contents"},
                  attributes: %{},
                  article_info: %Noizu.Cms.V2.Article.Info{post.article_info| tags: MapSet.new(["hello", "steve"]), status: :approved, editor: :test}
                } |> Noizu.Cms.V2.ArticleRepo.new_version!(@context)

      post_v3 = %Noizu.Cms.V2.Article.PostEntity{post|
                  title: %Noizu.MarkdownField{markdown: "My Alternative Updated Post"},
                  body: %Noizu.MarkdownField{markdown: "My Alternative Updated Contents"},
                  attributes: %{},
                  article_info: %Noizu.Cms.V2.Article.Info{post.article_info| tags: MapSet.new(["hello", "steve"]), status: :approved, editor: :test2}
                } |> Noizu.Cms.V2.ArticleRepo.new_version!(@context)

      # Verify New Revisions
      revision_key = elem(post_v2.article_info.revision, 2)
      revision_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(RevisionTable, revision_key, :error)
      revision = revision_record.entity
      assert revision.editor == :test
      assert revision.status == :approved
      assert revision.identifier ==  {{:ref, Noizu.Cms.V2.VersionEntity, {article_ref, {1, 1}}}, 1}

      revision_key = elem(post_v3.article_info.revision, 2)
      revision_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(RevisionTable, revision_key, :error)
      revision = revision_record.entity
      assert revision.editor == :test2
      assert revision.status == :approved
      assert revision.identifier ==  {{:ref, Noizu.Cms.V2.VersionEntity, {article_ref, {1, 2}}}, 1}



      # Verify parent and version updated.
      # Verify Version Correct in post_v2
      assert post_v2.article_info.parent == post.article_info.version
      assert post_v2.article_info.version == {:ref, Noizu.Cms.V2.VersionEntity, {article_ref, {1, 1}}}

      assert post_v3.article_info.parent == post.article_info.version
      assert post_v3.article_info.version == {:ref, Noizu.Cms.V2.VersionEntity, {article_ref, {1, 2}}}

      # Verify Index Not Updated
      index_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(IndexTable, article_ref, :error)
      assert index_record.editor != :test

      # Verify Tag Not Updated.
      tags = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(TagTable, article_ref, [])
             |> Enum.map(&(&1.tag))
      assert Enum.member?(tags, "hello") == false
      assert Enum.member?(tags, "steve") == false
      assert Enum.member?(tags, "apple") == true
      assert Enum.member?(tags, "test") == true
    end
  end

  @tag :cms
  @tag :cms_built_in
  test "Article - Delete Active Revision" do
    with_mocks([
      {ArticleTable, [:passthrough], MockArticleTable.strategy()},
      {IndexTable, [:passthrough], MockIndexTable.strategy()},
      {TagTable, [:passthrough], MockTagTable.strategy()},
      {VersionSequencerTable, [:passthrough], MockVersionSequencerTable.strategy()},
      {VersionTable, [:passthrough], MockVersionTable.strategy()},
      {RevisionTable, [:passthrough], MockRevisionTable.strategy()},
    ]) do
      Noizu.Support.Cms.V2.Database.MnesiaEmulator.reset()

    end
  end

  @tag :cms
  @tag :cms_built_in
  test "Article - Delete Inactive Revision" do
    with_mocks([
      {ArticleTable, [:passthrough], MockArticleTable.strategy()},
      {IndexTable, [:passthrough], MockIndexTable.strategy()},
      {TagTable, [:passthrough], MockTagTable.strategy()},
      {VersionSequencerTable, [:passthrough], MockVersionSequencerTable.strategy()},
      {VersionTable, [:passthrough], MockVersionTable.strategy()},
      {RevisionTable, [:passthrough], MockRevisionTable.strategy()},
    ]) do
      Noizu.Support.Cms.V2.Database.MnesiaEmulator.reset()

    end
  end

  @tag :cms
  @tag :cms_built_in
  test "Article - Delete Active Version" do
    with_mocks([
      {ArticleTable, [:passthrough], MockArticleTable.strategy()},
      {IndexTable, [:passthrough], MockIndexTable.strategy()},
      {TagTable, [:passthrough], MockTagTable.strategy()},
      {VersionSequencerTable, [:passthrough], MockVersionSequencerTable.strategy()},
      {VersionTable, [:passthrough], MockVersionTable.strategy()},
      {RevisionTable, [:passthrough], MockRevisionTable.strategy()},
    ]) do
      Noizu.Support.Cms.V2.Database.MnesiaEmulator.reset()
    end
  end

  @tag :cms
  @tag :cms_built_in
  test "Article - Delete Inactive Version" do
    with_mocks([
      {ArticleTable, [:passthrough], MockArticleTable.strategy()},
      {IndexTable, [:passthrough], MockIndexTable.strategy()},
      {TagTable, [:passthrough], MockTagTable.strategy()},
      {VersionSequencerTable, [:passthrough], MockVersionSequencerTable.strategy()},
      {VersionTable, [:passthrough], MockVersionTable.strategy()},
      {RevisionTable, [:passthrough], MockRevisionTable.strategy()},
    ]) do
      Noizu.Support.Cms.V2.Database.MnesiaEmulator.reset()

    end
  end

  @tag :cms
  @tag :cms_built_in
  test "Article - Expand from Revision" do
    with_mocks([
      {ArticleTable, [:passthrough], MockArticleTable.strategy()},
      {IndexTable, [:passthrough], MockIndexTable.strategy()},
      {TagTable, [:passthrough], MockTagTable.strategy()},
      {VersionSequencerTable, [:passthrough], MockVersionSequencerTable.strategy()},
      {VersionTable, [:passthrough], MockVersionTable.strategy()},
      {RevisionTable, [:passthrough], MockRevisionTable.strategy()},
    ]) do
      Noizu.Support.Cms.V2.Database.MnesiaEmulator.reset()

    end
  end

  @tag :cms
  @tag :cms_built_in
  test "Image Article CRUD" do
    assert true == true
  end

  @tag :cms
  @tag :cms_built_in
  test "File Article CRUD" do
    assert true == true
  end
end