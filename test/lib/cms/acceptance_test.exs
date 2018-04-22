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

    IO.inspect post
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

  test "Create New Version" do
    assert true == false
  end

  test "Query By Tag" do
    assert true == false
  end

  test "Delete Record" do
    assert true == false
  end

end