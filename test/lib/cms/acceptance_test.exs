#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.AcceptanceTest do
  use ExUnit.Case, async: false
  use Amnesia
  use Noizu.Cms.Database
  require Logger

  @context Noizu.ElixirCore.CallingContext.admin()

  @tag :cms
  test "Create New Record" do
    post = %Noizu.Cms.PostEntity{
      status: :enabled,
      type: :article,
      editor: {:ref, :test, :user},
      name: "Test Article",
      description: "Test Article Description",
      tags: MapSet.new([:test]),
      record: %Noizu.Cms.Post.Article{
        title: "A Test Article",
        body: "A Test Article BodY"
      },
    }

    sut = Noizu.Cms.PostRepo.create!(post, @context)

    # Verify Sut
    assert sut.identifier != nil

    # Verify Database Table
    record = Noizu.Cms.Database.PostTable.read!(sut.identifier)
    assert record.status == sut.status
    assert record.editor == sut.editor
    assert record.type == sut.type

    # Verify Version Table
    ref = Noizu.Cms.PostEntity.ref(sut)
    #[version_one] = Noizu.Cms.Database.Post.VersionTable.where!(post == ref) |> Amnesia.Selection.values
    version_one = Noizu.Cms.PostRepo.get_version!(1, ref, @context)
    assert version_one.post == ref
    assert version_one.version == 1
    assert version_one.created_on == sut.created_on
    assert version_one.editor == sut.editor

    version_two = Noizu.Cms.PostRepo.get_version!(2, ref, @context)
    assert version_two == nil

    # Verify Tag Table
    [tag_record] = Noizu.Cms.Database.Post.TagTable.read!(ref)
    assert tag_record.tag == :test

    # Verify History Table
    version_one_ref = Noizu.Cms.Post.VersionEntity.ref(version_one)
    [version_one_entry] = Noizu.Cms.PostRepo.get_history!(ref, @context)
    assert version_one_entry.version == 1
    assert version_one_entry.created_on == DateTime.to_unix(sut.created_on)
    assert version_one_entry.editor == sut.editor
    assert version_one_entry.note == :initial_version
    assert version_one_entry.post_version == version_one_ref

  end

  @tag :cms
  test "Versioning" do
    post = %Noizu.Cms.PostEntity{
      status: :enabled,
      type: :article,
      editor: {:ref, :test, :user},
      name: "Test Article 2",
      description: "Test Article Description",
      tags: [:test],
      record: %Noizu.Cms.Post.Article{
        title: "A Test Article",
        body: "A Test Article BodY"
      },
    }

    sut = Noizu.Cms.PostRepo.create!(post, @context)
    sut2 = %Noizu.Cms.PostEntity{sut| name: "Test Article 2 v2", tags: [:test, :test2], record: %Noizu.Cms.Post.Article{title: "New Title", body: "New Body"}}
           |> Noizu.Cms.PostRepo.update!(@context, %{note: "Version Two"})

    # Verify Sut
    assert sut.identifier != nil

    # Verify Database Table
    record = Noizu.Cms.Database.PostTable.read!(sut.identifier)
    assert record.status == sut.status
    assert record.editor == sut.editor
    assert record.type == sut.type

    # Verify Version Table
    ref = Noizu.Cms.PostEntity.ref(sut)

    # Verify Versioning
    version_one = Noizu.Cms.PostRepo.get_version!(1, ref, @context)
    assert version_one.post == ref
    assert version_one.version == 1
    assert version_one.created_on == sut.created_on
    assert version_one.editor == sut.editor

    version_two = Noizu.Cms.PostRepo.get_version!(2, ref, @context)
    assert version_two.post == ref
    assert version_two.version == 2
    assert version_two.editor == sut.editor

    # Verify Tag Table
    [tag_1, tag_2] = Noizu.Cms.Database.Post.TagTable.read!(ref)
    assert tag_1.tag == :test
    assert tag_2.tag == :test2

    # Verify History Table
    version_one_ref = Noizu.Cms.Post.VersionEntity.ref(version_one)
    version_two_ref = Noizu.Cms.Post.VersionEntity.ref(version_two)
    [version_one_entry, version_two_entry] = Noizu.Cms.PostRepo.get_history!(ref, @context)
    assert version_one_entry.version == 1
    assert version_one_entry.created_on == DateTime.to_unix(sut.modified_on)
    assert version_one_entry.editor == sut.editor
    assert version_one_entry.note == :initial_version
    assert version_one_entry.post_version == version_one_ref

    assert version_two_entry.version == 2

    expected_created_on = DateTime.to_unix(sut2.modified_on)
    assert abs(version_one_entry.created_on - expected_created_on) <= 2
    assert version_two_entry.editor == sut.editor
    assert version_two_entry.note == "Version Two"
    assert version_two_entry.post_version == version_two_ref
  end

  @tag :cms
  test "Query By Tag" do
    post = %Noizu.Cms.PostEntity{
      status: :enabled,
      type: :article,
      editor: {:ref, :test, :user},
      name: "Test Article",
      description: "Test Lookup by Tag",
      tags: [:unique_tag],
      record: %Noizu.Cms.Post.Article{
        title: "A Test Article",
        body: "A Test Article BodY"
      },
    }
    sut = Noizu.Cms.PostRepo.create!(post, @context)
    ref = Noizu.Cms.PostEntity.ref(sut)
    [match] = Noizu.Cms.PostRepo.by_tag!(:unique_tag, @context)
    assert match == ref
  end

  @tag :cms
  test "Delete Record" do
    post = %Noizu.Cms.PostEntity{
      status: :enabled,
      type: :article,
      editor: {:ref, :test, :user},
      name: "Test Article",
      description: "Test Lookup by Tag",
      tags: [:unique_tag],
      record: %Noizu.Cms.Post.Article{
        title: "A Test Article",
        body: "A Test Article BodY"
      },
    }

    sut = Noizu.Cms.PostRepo.create!(post, @context)
    ref = Noizu.Cms.PostEntity.ref(sut)
    Noizu.Cms.PostRepo.delete!(sut, @context)

    # Confirm there are no tag, version, or version table matches.
    version_one = Noizu.Cms.PostRepo.get_version!(1, ref, @context)
    assert version_one == nil

    # Tags
    tags = Noizu.Cms.Database.Post.TagTable.read!(ref)
    assert tags == nil

    # Version History
    history = Noizu.Cms.PostRepo.get_history!(ref, @context)
    assert history == []
  end

end