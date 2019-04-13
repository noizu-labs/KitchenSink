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
  test "Article - Create Version" do
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
        article_info: %Noizu.Cms.V2.Article.Info{tags: MapSet.new(["test2", "apple2"])}
      }
      post = Noizu.Cms.V2.ArticleRepo.create!(post, @context)

      # Spawn Version (note previously persisted entity record is not updated unless obtained from a version record.)
      version = Noizu.Cms.V2.ArticleRepo.create_version!(post, @context)
      IO.inspect version

      #------------------------------------------
      # Master Table: Approaches
      #------------------------------------------
      # 1. Always save to master table using revision as key
      # 1.b. revision records simply point to master table,
      #      special SREF type  ref.type.#{id}@#{version}-#{@revision}
      #      special ID type,   {:revision, {id, version, revision}},  id entry always set to active.
      # 2. Shallow master table, entity entry simple points to index record, entity method updated to pull active revision
      # 3. Master Table independent from versioning tables (what about article_info?)

      # What happens during CRUD?
      # Using 1.b,
      # - new revision generated during update unless special flag set.
      # - version/revision created during create unless special flag set.
      # - delete

      # What about having two types of id?  id and {:revision, {id, version, revision}}

      # How do we instantiate and track article_info details?
      # first populated in create.

      # How do we expose CMS enabled entities for api editing?

      # What happens during set_active, update_active, etc.

    end
  end

  @tag :cms
  @tag :cms_built_in
  test "Article - Create Revision" do
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
  test "Article - Update Active Revision" do
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
  test "Article - Update Inactive Revision" do
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