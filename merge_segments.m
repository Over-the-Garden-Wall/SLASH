function segments = merge_segments(segments, seed_pick, to_merge)
    segments.moments(seed_pick,:) = segments.moments(seed_pick,:) + segments.moments(to_merge,:);
    segments.size(seed_pick,:) = segments.size(seed_pick,:) + segments.size(to_merge,:);
end