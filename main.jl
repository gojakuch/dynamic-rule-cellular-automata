## Config (changes allowed)
latlen = 2000      # lattice length
iters = 500        # iterations
start_rule = 30    # starting rule
order2_rule = ""   # the rule of changing the rule
           #      - no changes (regular auomata)
           # >    - shift one to the right
           # >>   - shift two to the right
           # <    - shift one to the left
           # <<   - shift two to the left
           # +    - next rule (increases Wolfram's number)
           # -    - previous rule (decreases Wolfram's number)
           # |    - flip the rule by bits (mirror)
           # !    - perform "not" operation on each bit
           # +>>  - combination (increase rule and move two rules to the right). + operation cometh first
init = "."        # initial distribution of cells
           # .  - dot
           # r  - random
           # i  - inverse
           # :  - alternating black and white cells
           # .i - combination (inverse dot)
           # a  - get from init_arr
init_arr = []     # initial distribution of cells (leave blank if init is not "a").
                  # watch out, init_arr needs to be of length latlen


## Some interesting configurations
#=
starting with dot:
# 60 >>
# 60 >>|<<
# 60 >|<
# 60 <|>
# 60 >+<
# 101
# 101 >
# 101 >>
# 101 >|
# 101 |
random start:
# 40 +
# 40 >+<
# 50 >|<
# 60 >|<
# 105 >>
# 110 +<
# 110 <
# 110 +
# 110 -
# 110 --
# 110 >+++<
=#


## Config processing (changes not recommended)
# rule is a vector of integers (1s and 0s)
rule = [Int(i)-48 for i::Char in Base.bin(Unsigned(start_rule), 8, false)]

# a function to change the rule number by one
function next_rule!(rulevec::Vector{Int}, step::Int)::Nothing
    num::Int = parse(Int, join(rulevec), base=2)
    num += step
    if num > 255
        num -= 255
    elseif num < 0
        num = 256 + num
    end
    b::String = Base.bin(Unsigned(num), 8, false)
    for i in 1:length(rulevec)
        rulevec[i] = Int(b[i])-48
    end
    return nothing
end

# a function to change the rule with a bitwise "not"
function not!(rulevec::Vector{Int})::Nothing
    for i in 1:length(rulevec)
        rulevec[i] = Int(rulevec[i] == 0)
    end
    return nothing
end

# a mapping from characters to actions (order2 rules)
char2rule = Dict([
    '+' => r -> next_rule!(r, 1),
    '-' => r -> next_rule!(r, -1),
    '>' => r -> circshift!(r, copy(r), 1),
    '<' => r -> circshift!(r, copy(r), -1),
    '|' => r -> reverse!(r),
    '!' => r -> not!(r)
])


## Import and setup for visualization
using PyCall
import PyPlot; const plt = PyPlot
rcParams = PyDict(plt.matplotlib."rcParams")
rcParams["image.cmap"] = "binary"


## Data init (first line)
data = []
if occursin("r", init)
    push!(data, [rand((0, 1)) for i::Int in range(0, length=latlen)])
elseif occursin(".", init)
    push!(data, [((i==round(latlen/2)) ? 1 : 0) for i::Int in range(0, length=latlen)])
elseif occursin("a", init)
    push!(data, init_arr)
elseif occursin(":", init)
    push!(data, [i%2 for i::Int in range(0, length=latlen)])
end
if occursin("i", init)
    data = [[abs(i-1) for i::Int in data[1]]]
end


## The magic
for iter::Int in 1:iters
    new_line::Vector{Int} = []
    for i::Int in 1:length(data[iter])
        neigh::String = ""
        for j::Int in i-1:i+1
            aj::Unsigned = j # actual index to look at
            if (j <= 0)
                aj = length(data[iter])-1+j
            elseif (j > length(data[iter]))
                aj = j - length(data[iter])
            end
            neigh *= string(data[iter][aj])
        end
        push!(new_line, rule[8-parse(Int, neigh, base=2)])
    end
    push!(data, new_line)
    # change the rule according to the order2_rule
    for c::Char in order2_rule
        char2rule[c](rule)
    end
end


## Visualization
fig, ax = plt.subplots(figsize=(80, 80))
ax.matshow(data)
ax.axis(false)
display(plt.gcf()) # for Juno Plots window
plt.show()         # for terminal usage
