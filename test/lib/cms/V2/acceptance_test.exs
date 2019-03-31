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

  @tag :cms_wip
  @tag :cms
  @tag :cms_built_in
  test "Post Article CRUD" do
    with_mocks([
      {ArticleTable, [:passthrough], MockArticleTable.strategy()},
      {IndexTable, [:passthrough], MockIndexTable.strategy()},
      {TagTable, [:passthrough], MockTagTable.strategy()},
      {VersionSequencerTable, [:passthrough], MockVersionSequencerTable.strategy()},
      {VersionTable, [:passthrough], MockVersionTable.strategy()},
      {RevisionTable, [:passthrough], MockRevisionTable.strategy()},
    ]) do

      post = %Noizu.Cms.V2.Article.PostEntity{
        title: %Noizu.MarkdownField{markdown: "My Post"},
        body: %Noizu.MarkdownField{markdown: "My Post Contents"},
        attributes: %{},
        article_info: %Noizu.Cms.V2.Article.Info{tags: MapSet.new(["test"])}
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

      # @TODO Verify Version Record Injected (spawn agent to track writes in mock).
      # @TODO Verify Revision Record Injected (spawn agent to track writes in mock).
      # @TODO Verify Tag Records Injected (spawn agent to track writes in mock).
      # @TODO Verify Index Record Injected (spawn agent to track writes in mock).
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