require 'rgl/adjacency'
require 'net/http'
require 'rgl/traversal'
include RGL

URL = 'http://172.16.18.230:8080/'

def get_objects url, sector_id
	Net::HTTP.get(URI("#{url}api/sector/#{sector_id}/objects"))
end

def get_roots url, sector_id
	Net::HTTP.get(URI("#{url}api/sector/#{sector_id}/roots"))
end

def collect url, sector_id, trajectory
	Net::HTTP.post_form(URI("#{url}api/sector/#{sector_id}/company/Chushle/trajectory"), {'trajectory' => trajectory})
end

def call_collect dg, sector
	dg.each_vertex do |vertex|
		edges = dg.adjacent_vertices(vertex)
		if edges.length > 0
			edges.each do |edge|
				nesho = dg.adjacent_vertices(edge)
				if nesho.length > 0
					nesho.each do |nesho_kid|
						p collect(URL, sector, "#{vertex} #{edge} #{nesho_kid}")
					end
				else
					p collect(URL, sector, "#{vertex} #{edge}")
				end
			end
		else
			p collect(URL, sector, "#{vertex}")
		end
	end
end

def thread_function i
	objects = []
	roots = []

	get_objects(URL, i).each_line do |object|
		objects << object.match(/^(\d+)/)[0].to_i # split(' ').first.to_i
		objects << object.match(/\s(\d+)/)[0].to_i # split(' ').last.to_i
	end

	get_roots(URL, i).each_line do |line|
		roots << line.to_i
	end

	dg = DirectedAdjacencyGraph[*objects]

	roots.each do |root|
		dg.bfs_iterator(root).each do |linked|
			dg.remove_vertex linked
		end
	end

	call_collect dg, i
end

threads = []

(1..10).each do |i|
	threads << Thread.new{ thread_function(i) }
end

threads.each do |thread|
	thread.join
end