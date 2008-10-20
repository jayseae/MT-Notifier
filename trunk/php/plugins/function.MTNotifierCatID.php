<?php
# ===========================================================================
# Copyright Everitz Consulting.  Not for redistribution.
# ===========================================================================

function smarty_function_MTNotifierCatID($args, &$ctx) {
  $cat_id = '';
  if ($cat = $ctx->stash('category')) {
    $cat_id = $cat->id;
    return $cat_id;
  } else {
    if ($cat = $ctx->stash('archive_category')) {
      $cat_id = $cat->id;
      return $cat_id;
    } else {
      if ($entry = $ctx->stash('entry')) {
        $entry_id = $entry['entry_id'];
        $category = $ctx->mt->db->get_row("SELECT placement_category_id as cat_id FROM mt_placement WHERE placement_entry_id = $entry_id AND placement_is_primary = 1", ARRAY_A);
        if ($category) {
          $cat_id = $category['cat_id'];
          return $cat_id;
        }
      }
    }
  }
}
?>
