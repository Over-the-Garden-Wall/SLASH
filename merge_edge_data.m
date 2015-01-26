function edge_data = merge_edge_data(edge_data, orig_edge, merge_edge)

%     edge_data = 
% 
%          total: [594x1 double]
%            min: [594x1 double]
%            max: [594x1 double]
%          count: [594x1 double]
%            com: [594x3 double]
%        members: [594x2 double]
%     is_correct: [594x1 logical]

    edge_data.total(orig_edge) = edge_data.total(orig_edge) + edge_data.total(merge_edge);
    edge_data.min(orig_edge) = min(edge_data.min(orig_edge), edge_data.min(merge_edge));
    edge_data.max(orig_edge) = max(edge_data.max(orig_edge), edge_data.max(merge_edge));
    edge_data.count(orig_edge) = edge_data.count(orig_edge) + edge_data.count(merge_edge);
    edge_data.com(orig_edge,:) = (edge_data.com(orig_edge,:)*edge_data.count(orig_edge) + ...
         edge_data.com(merge_edge,:)*edge_data.count(merge_edge)) / ...
         (edge_data.count(orig_edge) + edge_data.count(merge_edge));
     
end    