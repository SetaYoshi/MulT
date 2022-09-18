require("mult")
local tic, toc = utils.tic, utils.toc

local sq = collider2d.rect(0, 0, 3, 4)
local cl = collider2d.circle(2, 2, 1)

print(collider2d.collide(sq, cl))

print("AAAAA")