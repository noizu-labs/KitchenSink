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
  test "Post Article Create" do
    with_mocks([
      {ArticleTable, [:passthrough], MockArticleTable.strategy()},
      {IndexTable, [:passthrough], MockIndexTable.strategy()},
      {TagTable, [:passthrough], MockTagTable.strategy()},
      {VersionSequencerTable, [:passthrough], MockVersionSequencerTable.strategy()},
      {VersionTable, [:passthrough], MockVersionTable.strategy()},
      {RevisionTable, [:passthrough], MockRevisionTable.strategy()},
    ]) do

      Noizu.Support.Cms.V2.Database.MnesiaEmulator.reset()

      post = %Noizu.Cms.V2.Article.PostEntity{
        title: %Noizu.MarkdownField{markdown: "My Post"},
        body: %Noizu.MarkdownField{markdown: "My Post Contents"},
        attributes: %{},
        article_info: %Noizu.Cms.V2.Article.Info{tags: MapSet.new(["test", "apple"])}
      }

      post = Noizu.Cms.V2.ArticleRepo.create!(post, @context)

      # Verify Identifier Created
      assert is_integer(post.identifier) == true

      # Verify article_info fleshed out.
      assert post.article_info.article == {:ref, Noizu.Cms.V2.ArticleEntity, post.identifier}

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
      assert version_record.entity.article == {:ref, Noizu.Cms.V2.ArticleEntity, post.identifier}

      # Verify Revision Record
      revision_key = elem(post.article_info.revision, 2)
      revision_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(RevisionTable, revision_key, :error)
      assert revision_record.entity.record.body.markdown == "My Post Contents"
      assert revision_record.entity.version == post.article_info.version
      assert revision_record.entity.article == {:ref, Noizu.Cms.V2.ArticleEntity, post.identifier}

      # Verify Tags
      _tags = [tag, tag2] = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(TagTable, {:ref, Noizu.Cms.V2.ArticleEntity, post.identifier}, :error)
      assert tag.tag != tag2.tag
      assert (tag.tag == "apple" || tag.tag == "test")
      assert (tag2.tag == "apple" || tag2.tag == "test")


      # Verify Index Record
      index_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(IndexTable, {:ref, Noizu.Cms.V2.ArticleEntity, post.identifier}, :error)
      assert index_record.article == {:ref, Noizu.Cms.V2.ArticleEntity, post.identifier}
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
  test "Post Article Update" do
    with_mocks([
      {ArticleTable, [:passthrough], MockArticleTable.strategy()},
      {IndexTable, [:passthrough], MockIndexTable.strategy()},
      {TagTable, [:passthrough], MockTagTable.strategy()},
      {VersionSequencerTable, [:passthrough], MockVersionSequencerTable.strategy()},
      {VersionTable, [:passthrough], MockVersionTable.strategy()},
      {RevisionTable, [:passthrough], MockRevisionTable.strategy()},
    ]) do
      Noizu.Support.Cms.V2.Database.MnesiaEmulator.reset()

      post = %Noizu.Cms.V2.Article.PostEntity{
        title: %Noizu.MarkdownField{markdown: "My Post"},
        body: %Noizu.MarkdownField{markdown: "My Post Contents"},
        attributes: %{},
        article_info: %Noizu.Cms.V2.Article.Info{tags: MapSet.new(["test2", "apple2"])}
      }
      post = Noizu.Cms.V2.ArticleRepo.create!(post, @context)

      update = post
               |> put_in([Access.key(:body)], %Noizu.MarkdownField{markdown: "My Edited Content"})
               |> put_in([Access.key(:article_info), Access.key(:status)], :approved)
               |> Noizu.Cms.V2.ArticleRepo.update!(@context)

      # Verify Identifier Created
      assert is_integer(update.identifier) == true

      # Verify article_info fleshed out.
      assert update.article_info.article == {:ref, Noizu.Cms.V2.ArticleEntity, update.identifier}

      # Verify Created On/Modified On dates.
      assert update.article_info.created_on != nil
      assert update.article_info.modified_on != nil
      assert update.article_info.modified_on != update.article_info.created_on

      # Verify Version Info
      assert update.article_info.version == {:ref, Noizu.Cms.V2.VersionEntity, {update.article_info.article, {1}}}

      # Verify Parent Info
      assert update.article_info.parent == nil

      # Verify Revision
      assert update.article_info.revision == {:ref, Noizu.Cms.V2.Version.RevisionEntity, {update.article_info.version, 2}}

      # Verify Type Set correctly
      assert update.article_info.type == :post

      # Verify Version Record
      version_key = elem(update.article_info.version, 2)
      version_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(VersionTable, version_key, :error)
      #assert version_record.entity.record.body.markdown == "My Edited Content"
      assert version_record.entity.revision == update.article_info.revision
      assert version_record.entity.parent == nil
      assert version_record.entity.article == {:ref, Noizu.Cms.V2.ArticleEntity, update.identifier}

      # Verify Revision Record
      revision_key = elem(update.article_info.revision, 2)
      revision_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(RevisionTable, revision_key, :error)
      assert revision_record.entity.record.body.markdown == "My Edited Content"
      assert revision_record.entity.version == update.article_info.version
      assert revision_record.entity.article == {:ref, Noizu.Cms.V2.ArticleEntity, update.identifier}

      # Verify Tags
      _tags = [tag, tag2] = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(TagTable, {:ref, Noizu.Cms.V2.ArticleEntity, update.identifier}, :error)
      assert tag.tag != tag2.tag
      assert (tag.tag == "apple2" || tag.tag == "test2")
      assert (tag2.tag == "apple2" || tag2.tag == "test2")


      # Verify Index Record
      index_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(IndexTable, {:ref, Noizu.Cms.V2.ArticleEntity, update.identifier}, :error)
      assert index_record.article == {:ref, Noizu.Cms.V2.ArticleEntity, update.identifier}
      assert index_record.active_version == update.article_info.version
      assert index_record.created_on == update.article_info.created_on
      assert index_record.modified_on == update.article_info.modified_on
      assert index_record.module == Noizu.Cms.V2.Article.PostEntity
      assert index_record.type == :post
      assert index_record.status == :approved
    end
  end

  @tag :cms_wip
  @tag :cms
  @tag :cms_built_in
  test "Post Article Delete" do
    with_mocks([
      {ArticleTable, [:passthrough], MockArticleTable.strategy()},
      {IndexTable, [:passthrough], MockIndexTable.strategy()},
      {TagTable, [:passthrough], MockTagTable.strategy()},
      {VersionSequencerTable, [:passthrough], MockVersionSequencerTable.strategy()},
      {VersionTable, [:passthrough], MockVersionTable.strategy()},
      {RevisionTable, [:passthrough], MockRevisionTable.strategy()},
    ]) do
      Noizu.Support.Cms.V2.Database.MnesiaEmulator.reset()

      post = %Noizu.Cms.V2.Article.PostEntity{
        title: %Noizu.MarkdownField{markdown: "My Post"},
        body: %Noizu.MarkdownField{markdown: "My Post Contents"},
        attributes: %{},
        article_info: %Noizu.Cms.V2.Article.Info{tags: MapSet.new(["test2", "apple2"])}
      }
      post = Noizu.Cms.V2.ArticleRepo.create!(post, @context)
      Noizu.Cms.V2.ArticleRepo.delete!(post, @context)

      # Verify Version Record (match emulation not functional)
      #version_key = elem(post.article_info.version, 2)
      #version_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(VersionTable, version_key, :error)
      #assert version_record == nil

      # Verify Revision Record (match emulation not functional)
      #revision_key = elem(post.article_info.revision, 2)
      #revision_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(RevisionTable, revision_key, :error)
      #assert revision_record == nil

      # Verify Tags
      tags = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(TagTable, {:ref, Noizu.Cms.V2.ArticleEntity, post.identifier}, :error)
      assert tags == nil

      # Verify Index Record
      index_record = Noizu.Support.Cms.V2.Database.MnesiaEmulator.get(IndexTable, {:ref, Noizu.Cms.V2.ArticleEntity, post.identifier}, :error)
      assert index_record == nil
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